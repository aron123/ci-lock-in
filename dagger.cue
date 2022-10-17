package todoapp

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	actions: {
		build: {
			// check out source code
			checkout: core.#Source & {
				path: "."
				exclude: [
					"node_modules",
					"coverage",
					".nyc_output",
					".vscode",
				]
			}

			// pull an image from Docker Hub, that already contains Node.js and bash
			pull: docker.#Pull & {
				source: "node:lts-gallium"
			}

			// set up workdir folder in the downloaded image
			setupImage: docker.#Set & {
				input: pull.output
				config: {
					workdir: "/app"
				}
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

            reportCoverage: bash.#Run & {
                input: measureCoverage.output
                script: contents:
            }
		}
	}
}
