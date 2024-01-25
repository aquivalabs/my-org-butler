# How to run

# Installation

1. Create Scratch org
    1. Adjust the DEV_HUB_ALIAS in `/scripts/create-scratch.org.sh`
    2. Run it via `./scripts/create-scratch.org.sh`
2. Post-install steps
    1. Add your OpenAI API Key to a new Principal Parameter called `ApiKey` in `Setup > Named Credential > External Credential > OpenAiApi.ApiKey`
    2. Add the `External Credential > OpenAiApi` to the `Permission Set MyOrgButler` 