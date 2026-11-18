// SPDX-License-Identifier: AGPL-3.0-or-later

import {
	desktopExecRunsPath,
	isAppImageIntegratorEntry,
	isWindowDesktopEntry,
	readDesktopEntryValue,
	setDesktopEntryValue,
} from '@electron/main/DesktopEntryText';
import {describe, expect, it} from 'vitest';

const STABLE_CLASSES = ['app.star.StarDesktop', 'star'];

function entry(...lines: Array<string>): string {
	return ['[Desktop Entry]', 'Type=Application', 'Name=Star', ...lines, ''].join('\n');
}

describe('readDesktopEntryValue', () => {
	it('reads keys written with spaces around the equals sign', () => {
		expect(readDesktopEntryValue(entry('StartupWMClass = star'), 'StartupWMClass')).toBe('star');
	});

	it('ignores localized keys and keys in other groups', () => {
		const contents = [
			'[Desktop Entry]',
			'Name[de]=Star DE',
			'Name=Star',
			'',
			'[Desktop Action new-dm]',
			'Exec=/opt/other %U',
		].join('\n');
		expect(readDesktopEntryValue(contents, 'Name')).toBe('Star');
		expect(readDesktopEntryValue(contents, 'Exec')).toBeNull();
	});
});

describe('setDesktopEntryValue', () => {
	it('replaces a spaced key in place without adding a duplicate', () => {
		const updated = setDesktopEntryValue(
			entry('StartupWMClass = star'),
			'StartupWMClass',
			'app.star.StarDesktop',
		);
		expect(updated.match(/StartupWMClass/g)).toHaveLength(1);
		expect(readDesktopEntryValue(updated, 'StartupWMClass')).toBe('app.star.StarDesktop');
	});

	it('drops repeated keys so the file stays valid', () => {
		const updated = setDesktopEntryValue(entry('StartupWMClass=a', 'StartupWMClass=b'), 'StartupWMClass', 'c');
		expect(updated.match(/StartupWMClass/g)).toHaveLength(1);
	});

	it('inserts a missing key at the end of the main group only', () => {
		const contents = ['[Desktop Entry]', 'Name=Star', '', '[Desktop Action a]', 'Name=A', ''].join('\n');
		expect(setDesktopEntryValue(contents, 'StartupWMClass', 'x')).toBe(
			['[Desktop Entry]', 'Name=Star', 'StartupWMClass=x', '', '[Desktop Action a]', 'Name=A', ''].join('\n'),
		);
	});
});

describe('desktopExecRunsPath', () => {
	it('matches the launch command as a whole program token', () => {
		expect(desktopExecRunsPath('star %U', 'star')).toBe(true);
		expect(desktopExecRunsPath('/usr/bin/star %U', 'star')).toBe(true);
		expect(desktopExecRunsPath('env FOO=1 /opt/Star/star %U', '/opt/Star/star')).toBe(true);
	});

	it('does not match other channels or the Flatpak export for the bare star command', () => {
		expect(desktopExecRunsPath('/opt/star-canary/star-canary %U', 'star')).toBe(false);
		expect(desktopExecRunsPath('star-canary %U', 'star')).toBe(false);
		expect(
			desktopExecRunsPath(
				'/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=star --file-forwarding app.star.Star @@u %U @@',
				'star',
			),
		).toBe(false);
	});

	it('does not match a sibling tar.gz install whose path starts with ours', () => {
		expect(desktopExecRunsPath('/home/u/star/star-canary-x64/star-canary %U', '/home/u/star/star')).toBe(
			false,
		);
		expect(desktopExecRunsPath('/home/u/star/star2 %U', '/home/u/star/star')).toBe(false);
	});

	it('reads paths quoted and escaped the way our own entry writes them', () => {
		expect(desktopExecRunsPath('"/home/u/My Apps/Flu\\\\$x.AppImage" %U', '/home/u/My Apps/Flu$x.AppImage')).toBe(true);
		expect(desktopExecRunsPath("'/home/u/My Apps/star.appimage' %U", '/home/u/My Apps/star.appimage')).toBe(true);
	});
});

describe('isWindowDesktopEntry', () => {
	const official = {wmClasses: STABLE_CLASSES, launchPath: '/opt/Star/star'};

	it('claims legacy entries that name the old window class or our binary', () => {
		expect(isWindowDesktopEntry(entry('StartupWMClass=Star', 'Exec=/somewhere/else %U'), official)).toBe(true);
		expect(isWindowDesktopEntry(entry('Exec=/opt/Star/star %U'), official)).toBe(true);
	});

	it('skips hidden entries and other channels', () => {
		expect(isWindowDesktopEntry(entry('Hidden=true', 'Exec=/opt/Star/star %U'), official)).toBe(false);
		expect(
			isWindowDesktopEntry(
				entry('StartupWMClass=app.star.StarDesktopCanary', 'Exec="/opt/star-canary/star-canary" %U'),
				{wmClasses: STABLE_CLASSES, launchPath: 'star'},
			),
		).toBe(false);
	});

	it('never claims other Electron apps when running on a stock Electron binary', () => {
		const stock = {wmClasses: STABLE_CLASSES, launchPath: '/usr/lib/electron44/electron'};
		expect(isWindowDesktopEntry(entry('Exec=electron44 /usr/lib/other/app.asar %U'), stock)).toBe(false);
		expect(isWindowDesktopEntry(entry('Exec=/usr/lib/electron44/electron %U', 'StartupWMClass=electron'), stock)).toBe(
			false,
		);
	});
});

describe('isAppImageIntegratorEntry', () => {
	const appImage = '/home/u/AppImages/star.appimage';

	it('accepts the entry Gear Lever writes for the AppImage', () => {
		const gearLever = entry(
			`Exec=${appImage} %U`,
			`TryExec=${appImage}`,
			'X-AppImage-Version=2026.1116.172250',
			'X-AppImage-Name=Star',
		);
		expect(isAppImageIntegratorEntry(gearLever, appImage)).toBe(true);
	});

	it('accepts the entry AppImageLauncher writes for the AppImage', () => {
		const launcher = entry(`Exec="${appImage}" %U`, 'X-AppImage-Identifier=0d1e');
		expect(isAppImageIntegratorEntry(launcher, appImage)).toBe(true);
	});

	it('leaves hand-written entries alone', () => {
		expect(isAppImageIntegratorEntry(entry(`Exec=${appImage} %U`, 'StartupWMClass=star'), appImage)).toBe(false);
	});

	it('leaves integrator entries for other AppImages alone', () => {
		const canary = entry('Exec=/home/u/AppImages/star_canary.appimage %U', 'X-AppImage-Name=Star Canary');
		expect(isAppImageIntegratorEntry(canary, appImage)).toBe(false);
		expect(isAppImageIntegratorEntry(entry('Exec=star %U', 'X-AppImage-Name=Star'), 'star')).toBe(false);
	});
});
