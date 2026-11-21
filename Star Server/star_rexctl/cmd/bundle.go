// SPDX-License-Identifier: AGPL-3.0-or-later

package cmd

import (
	"fmt"
	"path/filepath"

	"github.com/spf13/cobra"

	"github.com/starapp/star/star_rexctl/internal/envfile"
	"github.com/starapp/star/star_rexctl/internal/instance"
	"github.com/starapp/star/star_rexctl/internal/stack"
	"github.com/starapp/star/star_rexctl/internal/ui"
)

func newBundleCmd(app *App) *cobra.Command {
	var out string
	c := &cobra.Command{
		Use:    "bundle",
		Short:  "Write the compose files for running Star without rexctl",
		Hidden: true,
		Args:   noArgs,
		RunE: func(c *cobra.Command, _ []string) error {
			if out == "" {
				return ui.Refused("Pass --out with the folder to write to.", "")
			}
			images, err := stack.EmbeddedImages()
			if err != nil {
				return err
			}
			if len(images.Images) == 0 {
				return ui.Refused("This rexctl has no image set, so it can't pin Star's images.", "Use a released rexctl.")
			}
			if err := stack.Bundle(out, images.Images); err != nil {
				return ui.Wrap(err, fmt.Sprintf("Couldn't write the files to %s.", out), "Check that you can write to that folder.")
			}
			if err := envfile.WriteFileAtomic(filepath.Join(out, ".env.example"), []byte(instance.BundleEnv()), false); err != nil {
				return ui.Wrap(err, fmt.Sprintf("Couldn't write the files to %s.", out), "Check that you can write to that folder.")
			}
			if err := envfile.WriteFileAtomic(filepath.Join(out, "voice", "voice.env.example"), []byte(instance.VoiceBundleEnv()), false); err != nil {
				return ui.Wrap(err, fmt.Sprintf("Couldn't write the files to %s.", out), "Check that you can write to that folder.")
			}
			if err := envfile.WriteFileAtomic(filepath.Join(out, "voice", "edge.env.example"), []byte(instance.VoiceEdgeBundleEnv()), false); err != nil {
				return ui.Wrap(err, fmt.Sprintf("Couldn't write the files to %s.", out), "Check that you can write to that folder.")
			}
			return nil
		},
	}
	c.Flags().StringVar(&out, "out", "", "folder to write")
	return c
}
