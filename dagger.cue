package todoapp

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	client: env: {
		COVERALLS_REPO_TOKEN?:     dagger.#Secret
		COVERALLS_GIT_COMMIT?:     string
		COVERALLS_GIT_BRANCH:      string | *"master"
		COVERALLS_SERVICE_NUMBER?: string
	}
	actions: {
		build: {
			"node:lts-gallium": _ // Node.js v16
			"node:lts-fermium": _ // Node.js v14

			[docker_image=string]: {
				// check out source code
				checkout: core.#Source & {
					path: "."
					exclude: [
						"node_modules",
						"coverage",
						".nyc_output",
						".vscode",
						".github",
					]
				}

				// pull an image from Docker Hub, that already contains Node.js and bash
				pull: docker.#Pull & {
					source: "\(docker_image)"
				}

				// set up workdir folder in the downloaded image
				setupImage: docker.#Set & {
					input: pull.output
					config: workdir: "/app"
				}

				// copy code to Docker container's filesystem
				copy: docker.#Copy & {
					input:    setupImage.output
					contents: checkout.output
				}

				// install dependencies of the project
				install: bash.#Run & {
					input: copy.output
					script: contents: "npm ci"
				}

				// test code and measure coverage
				measureCoverage: bash.#Run & {
					input: install.output
					script: contents: "npm run coverage"
				}

				// report coverage stats to Coveralls
				reportCoverage: bash.#Run & {
					input: measureCoverage.output
					env: {
						COVERALLS_SERVICE_NAME:   "Dagger"
						COVERALLS_GIT_BRANCH:     client.env.COVERALLS_GIT_BRANCH
						COVERALLS_GIT_COMMIT:     client.env.COVERALLS_GIT_COMMIT
						COVERALLS_REPO_TOKEN:     client.env.COVERALLS_REPO_TOKEN
						COVERALLS_SERVICE_NUMBER: client.env.COVERALLS_SERVICE_NUMBER
						COVERALLS_PARALLEL:       "true"
					}
					script: contents: "[[ -n $COVERALLS_REPO_TOKEN ]] && cat ./coverage/lcov.info | ./node_modules/.bin/coveralls || echo 'Skipping coverage reporting.'"
				}
			}
		}
		mergeCoverageStats: {
			pull: docker.#Pull & {
				source: "ellerbrock/alpine-bash-curl-ssl:0.3.0"
			}

			call: bash.#Run & {
				input: pull.output
				env: {
					COVERALLS_REPO_TOKEN:     client.env.COVERALLS_REPO_TOKEN
					COVERALLS_SERVICE_NUMBER: client.env.COVERALLS_SERVICE_NUMBER
				}
				script: contents: "curl -k https://coveralls.io/webhook?repo_token=$COVERALLS_REPO_TOKEN -d \"payload[build_num]=$COVERALLS_SERVICE_NUMBER&payload[status]=done\""
			}
		}
	}
}
