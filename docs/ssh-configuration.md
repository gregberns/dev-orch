# SSH Configuration for Kestra to Host Communication

This guide provides instructions for configuring SSH on your host machine (macOS or Linux) so that a containerized Kestra instance can connect to it and execute `multipass` commands.

## Local Development (macOS)

Follow these steps to enable SSH on your macOS host and configure Kestra to connect to it.

### 1. Enable Remote Login (SSH Server)

Your Mac has a built-in SSH server, but it's disabled by default.

-   **Enable it via the command line (Recommended):**
    ```bash
    sudo systemsetup -setremotelogin on
    ```

-   **To verify**, open `System Settings` > `General` > `Sharing` and ensure the `Remote Login` service is turned on.

### 2. Create a Dedicated SSH Key for Kestra

For better security, create a new SSH key pair that will be used exclusively by Kestra.

1.  **Generate the key pair**:
    This command creates a new RSA key without a passphrase, which is required for automated services.
    ```bash
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/kestra_multipass_id_rsa -N ""
    ```
    This will create `kestra_multipass_id_rsa` (private key) and `kestra_multipass_id_rsa.pub` (public key) in your `~/.ssh` directory.

2.  **Authorize the new public key**:
    Add the new public key to your user's `authorized_keys` file. This grants access to any user/service that has the corresponding private key.
    ```bash
    cat ~/.ssh/kestra_multipass_id_rsa.pub >> ~/.ssh/authorized_keys
    ```

3.  **Set correct permissions**:
    SSH is strict about permissions. Ensure the `authorized_keys` file is not world-writable.
    ```bash
    chmod 600 ~/.ssh/authorized_keys
    ```

### 3. Configure Kestra Secrets

Kestra (Community Edition) reads secrets from environment variables. These need to be added to the `docker-compose.yaml` file.

1.  **Get the Host Address**:
    When running in a Docker container on macOS, you can use the special DNS name `host.docker.internal` to connect to the host machine.

2.  **Get your macOS Username**:
    ```bash
    whoami
    ```

3.  **Base64 Encode the Secrets**:
    Kestra expects the secret values to be Base64 encoded.

    -   **Encode the Host:**
        ```bash
        echo -n "host.docker.internal" | base64
        ```
    -   **Encode your Username** (replace `your_username`):
        ```bash
        echo -n "your_username" | base64
        ```
    -   **Encode the Private Key:**
        ```bash
        cat ~/.ssh/kestra_multipass_id_rsa | base64
        ```
    Copy the output from each command.


### 4. Restart Kestra

Apply the changes by restarting the Kestra container:
```bash
podman-compose up -d --force-recreate
```

Check `http://localhost:8080/ui/main/secrets` to ensure the secrets have been added.

## Production/Staging (Linux/Ubuntu)

The process for a Linux host is very similar, with minor differences in enabling the SSH server and determining the host IP address.

### 1. Install and Enable SSH Server

Most server distributions come with `openssh-server`, but if not, you can install it.

1.  **Install the SSH server**:
    ```bash
    sudo apt update
    sudo apt install openssh-server
    ```

2.  **Enable and start the service**:
    ```bash
    sudo systemctl enable ssh
    sudo systemctl start ssh
    ```

3.  **Verify the service is running**:
    ```bash
    sudo systemctl status ssh
    ```

### 2. Create and Authorize SSH Key

This process is identical to the macOS setup.

1.  **Generate the key pair**:
    ```bash
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/kestra_multipass_id_rsa -N ""
    ```

2.  **Authorize the new public key**:
    ```bash
    cat ~/.ssh/kestra_multipass_id_rsa.pub >> ~/.ssh/authorized_keys
    ```

3.  **Set correct permissions**:
    ```bash
    chmod 600 ~/.ssh/authorized_keys
    ```

### 3. Configure Kestra Secrets

1.  **Get the Host IP Address**:
    On Linux, `host.docker.internal` may not be available by default. The most reliable method is to find the IP address of the Docker bridge network interface on the host.
    ```bash
    ip addr show docker0 | grep "inet\\b" | awk '{print $2}' | cut -d/ -f1
    ```
    This will typically output an IP like `172.17.0.1`. Use this IP address for the `MULTIPASS_HOST` secret.

2.  **Get your Linux Username**:
    ```bash
    whoami
    ```

3.  **Base64 Encode the Secrets**:
    -   **Encode the Host IP** (replace `172.17.0.1` with the actual IP):
        ```bash
        echo -n "172.17.0.1" | base64
        ```
    -   **Encode your Username**:
        ```bash
        echo -n "your_username" | base64
        ```
    -   **Encode the Private Key:**
        ```bash
        cat ~/.ssh/kestra_multipass_id_rsa | base64
        ```

4.  **Update `docker-compose.yaml`**:
    Add the encoded values to the `environment` section of the `kestra` service, just like in the macOS example.

### 4. Restart Kestra

Finally, restart the Kestra container to apply the new environment variables:
```bash
docker-compose up -d --force-recreate
# or
podman-compose up -d --force-recreate
```
