// SPDX-License-Identifier: AGPL-3.0-or-later

package cmd

import (
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/starapp/star/star_rexctl/internal/instance"
	"github.com/starapp/star/star_rexctl/internal/ui"
)

func TestSudoCommand(t *testing.T) {
	cases := []struct {
		name string
		exe  string
		args []string
		dir  string
		want string
	}{
		{"home install keeps its full path", "/home/u/.local/bin/rexctl", []string{"migrate", "--experimental-native"}, "/home/u/star", "sudo /home/u/.local/bin/rexctl migrate --experimental-native --dir /home/u/star"},
		{"sudo finds rexctl by name", "/usr/bin/rexctl", []string{"status"}, "/opt/star", "sudo rexctl status --dir /opt/star"},
		{"names /usr/local/bin, which some sudo setups skip", "/usr/local/bin/rexctl", []string{"status"}, "/opt/star", "sudo /usr/local/bin/rexctl status --dir /opt/star"},
		{"leaves out a binary in the temporary folder", filepath.Join(os.TempDir(), "x", "out", "rexctl"), []string{"status"}, "", "sudo rexctl status"},
		{"keeps the folder the user passed", "/home/u/.local/bin/rexctl", []string{"install", "--experimental-native", "--dir", "x", "--domain", "chat.example.org"}, "/opt/star", "sudo /home/u/.local/bin/rexctl install --experimental-native --dir x --domain chat.example.org"},
		{"keeps --dir=", "/usr/bin/rexctl", []string{"backup", "--dir=/srv/star"}, "/srv/star", "sudo rexctl backup --dir=/srv/star"},
		{"no instance yet", "/usr/bin/rexctl", []string{"install", "--experimental-native"}, "", "sudo rexctl install --experimental-native"},
		{"quotes what the shell would split", "/home/my user/bin/rexctl", []string{"config", "set", "x=it's here"}, "/home/my user/star", `sudo '/home/my user/bin/rexctl' config set 'x=it'\''s here' --dir '/home/my user/star'`},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			if got := sudoCommand(c.exe, c.args, c.dir); got != c.want {
				t.Fatalf("got %q, want %q", got, c.want)
			}
		})
	}
}

func TestConfigSetHintLeavesOutValues(t *testing.T) {
	got := configSetFlags([]string{"storage.secret_key=hunter2", "--dir", "/opt/star", "--yes", "smtp.password", "hunter3"})
	want := []string{"config", "set", "--dir", "/opt/star", "--yes"}
	if strings.Join(got, " ") != strings.Join(want, " ") {
		t.Fatalf("got %q, want %q", got, want)
	}
}

func TestDefaultNativeDir(t *testing.T) {
	cases := map[string]string{
		"/home/u/star": "/opt/star",
		"/opt/star":    "/opt/star-native",
	}
	if os.Geteuid() != 0 {
		cases[t.TempDir()] = "/opt/star"
	}
	for dir, want := range cases {
		if got := defaultNativeDir(&instance.Instance{Dir: dir}); got != want {
			t.Errorf("for %s got %s, want %s", dir, got, want)
		}
	}
}

func TestUntrustedRefusal(t *testing.T) {
	cases := []struct {
		name string
		err  *instance.UntrustedError
		msg  string
		fix  string
	}{
		{"found under a folder others can change", &instance.UntrustedError{Path: "/home/u", Dir: "/home/u/star", Shared: true}, "other accounts can change /home/u, so root doesn't use it on its own", "pass --dir /home/u/star."},
		{"instance folder others can change", &instance.UntrustedError{Path: "/mnt/user/appdata/star", Dir: "/mnt/user/appdata/star", Shared: true, Inside: true}, "Other accounts can change /mnt/user/appdata/star, so root doesn't use the instance in it.", "chmod go-w /mnt/user/appdata/star,"},
		{"state folder others can change", &instance.UntrustedError{Path: "/srv/star/.rexctl", Dir: "/srv/star", Shared: true, Inside: true}, "Other accounts can change /srv/star/.rexctl, so root doesn't use the instance in /srv/star.", "chmod go-w /srv/star/.rexctl,"},
		{"link in a folder others can change", &instance.UntrustedError{Path: "/srv/shared", Dir: "/srv/shared/star", Shared: true, Link: "/srv/shared/star"}, "/srv/shared/star is a link in /srv/shared", "Pass --dir"},
		{"another owner", &instance.UntrustedError{Path: "/home/v/star", Dir: "/home/v/star"}, "another account owns /home/v/star", "pass --dir /home/v/star."},
		{"record file", &instance.UntrustedError{Path: "/etc/rexctl"}, "Accounts other than root can change /etc/rexctl", "Make root its owner"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			var ee *ui.ExitError
			if !errors.As(untrustedRefusal(c.err), &ee) || !strings.Contains(ee.Msg, c.msg) || !strings.Contains(ee.Fix, c.fix) {
				t.Fatalf("got %+v, want %q and %q", ee, c.msg, c.fix)
			}
		})
	}
}

func TestMovedRefusalPointsAtTheNewInstance(t *testing.T) {
	r := movedRefusal(&instance.MovedError{Dir: "/home/u/star", To: "/opt/star"})
	if !strings.Contains(r.Msg, "/opt/star") || !strings.HasSuffix(r.Fix, "status --dir /opt/star.") || !strings.Contains(r.Fix, "sudo ") {
		t.Fatalf("got %q and %q", r.Msg, r.Fix)
	}
}

func TestMarkMovedRecordsTheNewFolder(t *testing.T) {
	old := instance.MachineRecordPath
	t.Cleanup(func() { instance.MachineRecordPath = old })
	instance.MachineRecordPath = filepath.Join(t.TempDir(), "etc", instance.RecordFileName)
	dir := t.TempDir()
	if err := os.MkdirAll(filepath.Join(dir, instance.StateDirName), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, instance.StateDirName, instance.StateFileName), []byte(`{"schema":6,"project":"star","runtime":"compose"}`), 0o600); err != nil {
		t.Fatal(err)
	}
	app := &App{UI: ui.New(ui.Options{Stdout: io.Discard, Stderr: io.Discard})}
	markMoved(app, &instance.Instance{Dir: dir}, "/opt/star")
	got, err := instance.Find(dir)
	if err != nil || got.State.MovedTo != "/opt/star" {
		t.Fatalf("got %+v, %v, want the state to name /opt/star", got, err)
	}
}
