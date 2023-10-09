
## Auto-Injected Credentials

A common use case when running NodeZero involves [injecting](https://docs.horizon3.ai/reference/injecting_credentials/) a known good credential
into a pentest.  Credentials are typically injected manually from the Real-Time View in Portal while the pentest is running.  This is 
impractical however if you want to inject a credential into a pentest that runs on an [automated schedule](https://docs.horizon3.ai/reference/scheduling/).

**Auto-injected credentials enable you to inject credentials automatically into a scheduled pentest.**
This support allows you to pre-configure the credentials you want to auto-inject.
You then add those pre-configured credentials to your pentest configuration, and 
they will be auto-injected when the pentest starts.

This is particularly useful for running [Password Audit](https://docs.horizon3.ai/getting_started/ad_password_audit/) pentests 
on an automated schedule, as they require a credential to be injected.

> This support was added in h3-cli version `2023-10-13: October, 2023`.  To upgrade your existing h3-cli installation, see [here](../readme.md#upgrading-h3-cli).


## How it works

At a high level, the steps for configuring an auto-injected credental are:

1. Install h3-cli and spin up a [NodeZero Runner](touchless-nodezero.md) on your system (the Runner is what auto-injects the credential).
2. Use h3-cli to create an auto-injected credential.
3. Add the auto-injected credential to your pentest configuration/template.

That's all.  The credential will be auto-injected by the Runner when the pentest starts.

### Step 1: Install h3-cli and spin up a NodeZero Runner

Installing h3-cli and spinning up a NodeZero Runner can be done with a single operation. See [here](touchless-nodezero.md#install-option-1-the-easy-way-recommended) 
for instructions.

### Step 2: Create an auto-injected credential

Use the h3-cli command `h3 create-auto-injected-credential` to create an auto-injected credential. For example:

```shell
h3 create-auto-injected-credential '{"key_type":"cleartext", "user":"MYDOMAIN\myuser", "cleartext":"mypassword"}'
```

You can also omit the JSON input from the command, in which case you'll be prompted for it. This would prevent any sensitive data
in the input being recorded in your bash history.

> ❗ If you see errors like `h3: command not found`, try adding the `h3-cli/bin` directory to your `PATH`, 
> for example: `export PATH="/path/to/h3-cli/bin:$PATH"` (swap `/path/to` with the actual path on your system).

There are several types of credentials you can create. Each type requires different parameters. Some examples are:

```shell
h3 create-auto-injected-credential '{"key_type":"cleartext", "user":"MYDOMAIN\myuser", "cleartext":"mypassword"}'
h3 create-auto-injected-credential '{"key_type":"cleartext", "user":"myuser", "cleartext":"mypassword", "ip":"192.168.1.2"}'
h3 create-auto-injected-credential '{"key_type":"ntlm_hash", "user":"myuser", "hash":"myhash"}'
h3 create-auto-injected-credential '{"key_type":"ntlm_hash", "user":"myuser", "hash":"myhash", "ip":"192.168.1.3"}'
h3 create-auto-injected-credential '{"key_type":"aws", "aws_access_key_id":"AK123456789ABCDEFGHI", "aws_secret_access_key":"DSAfR...BOl0c"}'
h3 create-auto-injected-credential '{"key_type":"aws", "aws_access_key_id":"AK123456789ABCDEFGHI", "aws_secret_access_key":"DSAfR...BOl0c", "aws_session_token":"IQoJb3JpZ2lu...BUTWASw="}'
```

See [here](https://docs.horizon3.ai/reference/injecting_credentials/) for more information about injected credentials.


#### ❗ Security considerations

There are a number of security considerations to be aware of when using auto-injected credentials. 

* **Stored on your system:** Auto-injected credentials are encrypted and stored locally in a file on the same machine as the h3-cli and Runner.
  The credential's existence is registered with H3; however H3 does NOT store the credential's secret (i.e. the cleartext password, hash, or aws key) on its systems,
  not even in encrypted form. The encrypted secret is stored on the local filesystem 
  under the `~/.h3` directory (same location as the h3-cli API key).
* **Encrypted:** Auto-injected credentials are encrypted using an AES-256 key that H3 creates and secures on its backend systems.
* **Unique keys:** Each auto-injected credential has its own unique AES-256 key. 
* **Re-encrypting a credential:** You can re-encrypt a credential by re-invoking `h3 create-auto-injected-credential`. A new AES-256 key is generated each time 
  the command is executed.

These security measures were taken to best ensure the security of your auto-injected credentials - even in the 
event that your system or H3 systems are compromised.  

If H3 systems are compromised, the attacker could 
potentially gain access to the AES key, but they would not have access to the encrypted credential, which is stored
on your system.  

Similarly, if your system is compromised, the attacker could potentially gain access to the
encrypted credential and your h3-cli API key, but they would not have access to the AES key needed to decrypt the credential,
which is stored on H3's systems.  

Both H3 systems *and* your system would have to be compromised simultaneously 
for an attacker to decrypt your auto-injected credential.


### Step 3: Add the auto-injected credential to your pentest configuration

You can add an auto-injected credential to your pentest configuration/template in the Portal
under the **Run Pentest** wizard.

When the pentest is initiated, the Runner is notified and it auto-injects the configured credentials into the pentest.
Some important notes to be aware of:

* **The Runner must be active in order to auto-inject credentials.** If the Runner is not active, the credentials will not be injected.
* **The Runner that auto-injects credentials does not have to be the same Runner that launches NodeZero.**
  Any Runner can auto-inject credentials into any pentest. For example, a Runner can auto-inject credentials into an external pentest, 
  even though external pentests are not launched by Runners (external pentests are launched automatically in the H3 cloud). 
  
  This independence between (1) launching NodeZero, and (2) auto-injecting credentials, gives you some flexibility in how you manage your Runners and credentials. 
* **Multiple auto-injected credentials** can be added to the same pentest configuration. Similarly, the same auto-injected credential 
can be added to multiple pentest configurations.
* **You can store multiple auto-injected credentials across multiple Runners in your environment.** H3 keeps track of which Runners have access to which 
credentials, in order to notify the correct Runner to auto-inject the credential when the pentest starts.
* ❗ **Do NOT store the same auto-injected credential on multiple Runners.** A new AES-256 key is created each time `h3 create-auto-injected-credential` is
  invoked.  Once you create the same auto-injected credential on a second Runner, the encrypted secret stored on the first Runner will no longer be valid
  and will fail to be decrypted and injected.

  > An auto-injected credential is "the same" as another if all non-secret input fields are identical (key_type, user, ip, aws_access_key_id)
    


## Listing and deleting auto-injected credentials

You can use h3-cli to list all auto-injected credentials registered under your account:

```shell
h3 auto-injected-credentials
```

Use the following command to delete an auto-injected credential:

```shell
h3 delete-auto-injected-credential {uuid}
```

This will delete the credential's registration on the backend, and also notify the Runner to delete the encrypted file stored 
locally on the Runner's machine.

