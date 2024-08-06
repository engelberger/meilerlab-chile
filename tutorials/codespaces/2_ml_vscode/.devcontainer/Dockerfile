FROM rosettacommons/rosetta:ml

# Install any additional tools you might need
RUN apt-get update && apt-get install -y \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /work

# Set environment variables if needed
ENV PATH="/usr/local/bin:${PATH}"