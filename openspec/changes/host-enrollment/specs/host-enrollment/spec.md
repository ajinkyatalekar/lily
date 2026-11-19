## Purpose

Lets the operator bring a machine into the fleet and see whether it is reachable. A host is a machine running the host agent; nothing can be placed on a machine until it is enrolled as a host.

## ADDED Requirements

### Requirement: The operator can add a host
The control plane SHALL let the operator add a host by name and SHALL return a one-time enrollment token for it. A name SHALL be 1 to 63 characters of lowercase letters, digits and hyphens, and unique. A new host SHALL have the status `pending`.

#### Scenario: Add a host
- **WHEN** the operator adds a host named `node-1`
- **THEN** the host is listed with status `pending` and the response carries an enrollment token

#### Scenario: Duplicate name
- **WHEN** the operator adds a host whose name is already taken
- **THEN** the call is rejected as already existing and no host is created

#### Scenario: Invalid name
- **WHEN** the operator adds a host whose name is empty, longer than 63 characters, or contains any other character
- **THEN** the call is rejected as invalid and no host is created

### Requirement: An enrollment token is shown once and expires
The control plane SHALL return an enrollment token only in the response that issued it, and SHALL NOT accept it more than one hour after it was issued.

#### Scenario: Token is not shown again
- **WHEN** the operator reads or lists a host after adding it
- **THEN** the response contains no enrollment token

#### Scenario: Expired token
- **WHEN** an agent presents a token more than one hour after it was issued
- **THEN** enrollment is rejected and the host stays `pending`

### Requirement: An agent exchanges a token for a host credential exactly once
The control plane SHALL exchange a valid enrollment token for a credential that identifies that one host. It SHALL reject a used, expired or unknown token with one indistinguishable error.

#### Scenario: Valid token
- **WHEN** an agent presents an unused, unexpired token
- **THEN** it receives a credential for that host, and the host turns `online` once the agent connects

#### Scenario: Reused token
- **WHEN** a second agent presents a token that was already exchanged
- **THEN** enrollment is rejected and the first agent's credential still works

#### Scenario: Unknown token
- **WHEN** an agent presents a token the control plane never issued
- **THEN** enrollment is rejected with the same error as a used or expired token

### Requirement: The operator can issue a new enrollment token for a host
The control plane SHALL let the operator issue a new token for any host. Issuing one SHALL cancel any earlier unused token for that host. Exchanging it SHALL replace the host's credential.

#### Scenario: New token for a pending host
- **WHEN** the operator issues a new token for a host whose first token expired, and an agent presents the new token
- **THEN** the agent is enrolled and the host turns `online`

#### Scenario: Earlier token is cancelled
- **WHEN** the operator issues a new token for a host and an agent presents the earlier, unused token
- **THEN** enrollment is rejected

#### Scenario: Re-enrolling replaces the credential
- **WHEN** an agent enrolls with a new token for a host that already had a credential
- **THEN** the old credential is rejected from then on

### Requirement: A host is online only while its agent is reporting in
The control plane SHALL report a host as `online` while an agent holding its credential is reporting in, and as `offline` within 30 seconds of its last report.

#### Scenario: Agent stops
- **WHEN** the agent of an online host exits
- **THEN** the host is reported `offline` within 30 seconds

#### Scenario: Agent hangs without closing its connection
- **WHEN** the agent of an online host is frozen so that its connection stays open but silent
- **THEN** the host is reported `offline` within 30 seconds

#### Scenario: Agent returns
- **WHEN** the agent of an offline host starts again with its stored credential and no token
- **THEN** the host is reported `online`

#### Scenario: Control plane restarts
- **WHEN** the control plane restarts while an agent is running
- **THEN** the agent reconnects by itself and the host is reported `online` again without operator action

### Requirement: A host is identified only by its credential
The control plane SHALL derive a reporting agent's host from its credential alone and SHALL reject a report that carries no valid credential.

#### Scenario: Invalid credential
- **WHEN** an agent reports in with a credential the control plane does not recognize
- **THEN** the report is rejected as unauthenticated and no host changes status

### Requirement: The operator can remove a host
The control plane SHALL let the operator remove a host. Removal SHALL invalidate its credential and any unused token and SHALL disconnect its agent.

#### Scenario: Remove a connected host
- **WHEN** the operator removes an online host
- **THEN** the host is no longer listed and every later report from its agent is rejected

#### Scenario: Remove an unknown host
- **WHEN** the operator removes a host that does not exist
- **THEN** the call fails as not found

### Requirement: The agent keeps its credential across restarts and keeps it private
The host agent SHALL store its credential in a file readable only by the user it runs as, and SHALL reuse it on later starts.

#### Scenario: Credential file permissions
- **WHEN** an agent has enrolled
- **THEN** its credential file exists and no other user can read it

#### Scenario: Started with neither token nor credential
- **WHEN** the agent is started with no enrollment token and no stored credential
- **THEN** it exits with an error that says an enrollment token is required

### Requirement: The agent retries when the control plane is unreachable and stops when it is rejected
The host agent SHALL keep retrying while the control plane cannot be reached, and SHALL exit when the control plane rejects its credential.

#### Scenario: Control plane unreachable
- **WHEN** the control plane cannot be reached for several minutes and then returns
- **THEN** the agent is still running and the host turns `online` without operator action

#### Scenario: Credential rejected
- **WHEN** the control plane rejects the agent's credential because the host was removed or re-enrolled
- **THEN** the agent exits with an error that says the host must be enrolled again

### Requirement: The agent does not send secrets over an unencrypted connection
The host agent SHALL refuse to use a control-plane address that is not encrypted, unless it was explicitly started in development mode.

#### Scenario: Plain address without development mode
- **WHEN** the agent is started with an unencrypted control-plane address and without development mode
- **THEN** it exits with an error before sending its token or credential

#### Scenario: Plain address in development mode
- **WHEN** the agent is started with an unencrypted control-plane address and with development mode
- **THEN** it connects, and logs a warning that the connection is not encrypted

### Requirement: The web app shows hosts and lets the operator manage them
The web app SHALL list every host with its name and status, refresh status without a page reload, and let the operator add a host, issue a new token, and remove a host.

#### Scenario: Status updates on its own
- **WHEN** a listed host goes from `online` to `offline`
- **THEN** the hosts page shows `offline` within 40 seconds without a reload

#### Scenario: Add a host from the web app
- **WHEN** the operator adds a host on the hosts page
- **THEN** the page shows the token inside the exact command to run on the machine, and states that it will not be shown again

#### Scenario: Add fails
- **WHEN** the operator adds a host with a name that is taken or invalid
- **THEN** the page shows why and creates nothing

#### Scenario: Remove needs confirmation
- **WHEN** the operator chooses to remove a host
- **THEN** the page asks for confirmation naming the host, and removes it only if confirmed
