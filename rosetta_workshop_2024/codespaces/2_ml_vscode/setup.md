## Setup

### Prerequisites

1. Ensure you have a working Docker installation on your system:
   - For Unix-based systems (Linux/macOS): Install Docker Engine. You can follow the official Docker documentation for [Linux](https://docs.docker.com/engine/install/) or [macOS](https://docs.docker.com/desktop/install/mac-install/).
   - For Windows: Install Docker Desktop. Follow the [official Docker Desktop for Windows installation guide](https://docs.docker.com/desktop/install/windows-install/).

   After installation, verify that Docker is running correctly by opening a terminal (or PowerShell on Windows) and running:
   ```bash
   docker --version
   docker run hello-world
   ```

2. Install Visual Studio Code on your system. You can download it from the [official VS Code website](https://code.visualstudio.com/).

3. Install the "Remote - Containers" extension in VS Code:
   - Open VS Code
   - Go to the Extensions view by clicking on the square icon in the left sidebar or pressing `Ctrl+Shift+X`
   - Search for "Remote - Containers"
   - Click "Install"

### Setting up the Tutorial Environment

1. Clone the repository containing the tutorial files:
   ```bash
   git clone https://github.com/engelberger/rosetta_ml_tutorial.git
   cd rosetta_ml_tutorial
   ```

2. Before setting up the DevContainer, we need to download the necessary model weights. Follow the instructions for your operating system:

   #### For Unix-based systems (Linux/macOS):

   Run the following commands in your terminal:

   ```bash
   mkdir -p ~/rosetta_ml_weights
   cd ~/rosetta_ml_weights
   wget https://raw.githubusercontent.com/engelberger/tutorials/main/tutorials/2_ml_vscode/download_weights.sh
   chmod +x download_weights.sh
   ./download_weights.sh
   ```

   #### For Windows:

   1. Open PowerShell as Administrator
   2. Run the following commands:

   ```powershell
   mkdir -Force $env:USERPROFILE\rosetta_ml_weights
   cd $env:USERPROFILE\rosetta_ml_weights
   Invoke-WebRequest -Uri https://raw.githubusercontent.com/engelberger/tutorials/main/tutorials/2_ml_vscode/download_weights.sh -OutFile download_weights.sh
   # Install Windows Subsystem for Linux if not already installed
   wsl --install -d Ubuntu
   # Run the bash script using WSL
   wsl bash download_weights.sh
   ```

   These commands will download and extract the required model weights into the `~/rosetta_ml_weights` directory (Unix) or `%USERPROFILE%\rosetta_ml_weights` directory (Windows).

3. Once the weights are downloaded, open the `rosetta_ml_tutorial` folder in VS Code:
   
   For Unix:
   ```bash
   code ~/path/to/rosetta_ml_tutorial
   ```
   
   For Windows:
   ```powershell
   code $env:USERPROFILE\path\to\rosetta_ml_tutorial
   ```

4. When VS Code opens, you should see a notification asking if you want to reopen the folder in a container. Click "Reopen in Container". Alternatively, you can use the command palette (F1) and select "Remote-Containers: Reopen in Container".

5. VS Code will build the Docker container and set up the environment. This may take a few minutes the first time.

6. Once the container is ready, you'll be working inside the Rosetta ML environment with access to the downloaded weights.

Now, you can proceed with the rest of the tutorial, starting from "1. Prepare the Input Structure". All commands can be run directly in the VS Code integrated terminal.

Note: If you encounter any issues with Docker, ensure that the Docker daemon is running and that you have the necessary permissions to use Docker on your system.