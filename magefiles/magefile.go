package main

import (
	"os"
	"runtime"

	"github.com/magefile/mage/sh"
)

func Build() error {
	isWindows := runtime.GOOS == "windows"

	if err := sh.RunV("npm", "ci"); err != nil {
		return err
	}

	if err := sh.RunV("npm", "run", "coverage"); err != nil {
		return err
	}

	env := make(map[string]string)
	env["COVERALLS_PARALLEL"] = "true"
	env["COVERALLS_SERVICE_NAME"] = "magefile"
	env["COVERALLS_GIT_BRANCH"] = os.Getenv("COVERALLS_GIT_BRANCH")
	env["COVERALLS_GIT_COMMIT"] = os.Getenv("COVERALLS_GIT_COMMIT")
	env["COVERALLS_REPO_TOKEN"] = os.Getenv("COVERALLS_REPO_TOKEN")
	env["COVERALLS_SERVICE_NUMBER"] = os.Getenv("COVERALLS_SERVICE_NUMBER")

	if isWindows {
		return sh.RunWithV(env, "cmd", "/C", "IF DEFINED COVERALLS_REPO_TOKEN (cat .\\coverage\\lcov.info | .\\node_modules\\.bin\\coveralls) ELSE (echo 'Skipping coverage reporting.')")
	} else {
		return sh.RunWithV(env, "bash", "-c", "[[ -n $COVERALLS_REPO_TOKEN ]] && cat ./coverage/lcov.info | ./node_modules/.bin/coveralls || echo 'Skipping coverage reporting.'")
	}
}

func mergeCoverageStats() error {
	env := make(map[string]string)
	env["COVERALLS_REPO_TOKEN"] = os.Getenv("COVERALLS_REPO_TOKEN")
	env["COVERALLS_SERVICE_NUMBER"] = os.Getenv("COVERALLS_SERVICE_NUMBER")

	return sh.RunWithV(env, "curl", "-k", "https://coveralls.io/webhook?repo_token=$COVERALLS_REPO_TOKEN", "-d", "payload[build_num]=$COVERALLS_SERVICE_NUMBER&payload[status]=done")
}
