# Minimal Dockerfile for unit tests
# Use Alpine Linux for minimal size
FROM node:20-alpine

# Install bash, git, and gh cli in a single layer
RUN apk add --no-cache bash git curl ca-certificates && \
    # Detect architecture and download appropriate gh cli binary
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        GH_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        GH_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -fsSL "https://github.com/cli/cli/releases/download/v2.40.1/gh_2.40.1_linux_${GH_ARCH}.tar.gz" | tar xz -C /tmp && \
    mv "/tmp/gh_2.40.1_linux_${GH_ARCH}/bin/gh" /usr/local/bin/ && \
    chmod +x /usr/local/bin/gh && \
    rm -rf /tmp/gh_* && \
    # Clean up
    apk del curl && \
    rm -rf /var/cache/apk/*

# mock claude binary
RUN touch /usr/local/bin/claude && chmod +x /usr/local/bin/claude

# Set the default command
CMD ["/bin/bash"]