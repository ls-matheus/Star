// SPDX-License-Identifier: AGPL-3.0-or-later

package main

import (
	"os"

	"star.example/star/star_rexctl/cmd"
)

var (
	version = "dev"
	commit  = ""
)

func main() {
	os.Exit(cmd.Execute(version, commit))
}
