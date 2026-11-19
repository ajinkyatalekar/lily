## Purpose

Keeps everyone but the operator out of the control plane until customer accounts exist. One shared secret protects every operator API call and unlocks the web app.

## ADDED Requirements

### Requirement: Every operator API call requires the operator secret
The control plane SHALL reject any operator API call that does not present the configured operator secret. The rejection SHALL be the same whether the secret is missing or wrong.

#### Scenario: Call without a secret
- **WHEN** a client calls an operator API without a secret
- **THEN** the call fails as unauthenticated and returns no data

#### Scenario: Call with a wrong secret
- **WHEN** a client calls an operator API with a secret that is not the configured one
- **THEN** the call fails with the same unauthenticated error as a missing secret and returns no data

#### Scenario: Call with the right secret
- **WHEN** a client calls an operator API with the configured secret
- **THEN** the call is processed

### Requirement: The control plane refuses to start without a strong operator secret
The control plane SHALL NOT serve any request unless an operator secret of at least 32 characters is configured.

#### Scenario: No secret configured
- **WHEN** the control plane is started with no operator secret
- **THEN** it exits with an error that names the missing setting, and serves nothing

#### Scenario: Short secret configured
- **WHEN** the control plane is started with an operator secret shorter than 32 characters
- **THEN** it exits with an error that states the minimum length, and serves nothing

### Requirement: The web app stays locked until the operator secret is entered
The web app SHALL show only an unlock screen until the operator enters a secret the control plane accepts. It SHALL keep the secret for the current browser tab only.

#### Scenario: Unlock with the right secret
- **WHEN** the operator enters the configured secret on the unlock screen
- **THEN** the web app shows the hosts page

#### Scenario: Unlock with a wrong secret
- **WHEN** the operator enters a wrong secret
- **THEN** the web app stays on the unlock screen and says the secret was not accepted

#### Scenario: A new browser session starts locked
- **WHEN** the operator has unlocked the web app and then opens it in a new browser session
- **THEN** the web app shows the unlock screen
