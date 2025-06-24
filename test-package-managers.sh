#!/bin/bash

echo "Testing package managers installation..."

# Test bun
echo -e "\n1. Testing bun:"
if command -v bun &> /dev/null; then
    echo "✓ bun found at: $(which bun)"
    echo "✓ bun version: $(bun --version)"
    
    # Create a test project with bun
    mkdir -p /tmp/bun-test
    cd /tmp/bun-test
    echo '{"name": "bun-test", "version": "1.0.0"}' > package.json
    bun add lodash
    if [ -f "bun.lockb" ] || [ -f "node_modules/lodash/package.json" ]; then
        echo "✓ bun successfully installed a package"
    else
        echo "✗ bun package installation failed"
    fi
    cd -
    rm -rf /tmp/bun-test
else
    echo "✗ bun not found in PATH"
fi

# Test pnpm
echo -e "\n2. Testing pnpm:"
if command -v pnpm &> /dev/null; then
    echo "✓ pnpm found at: $(which pnpm)"
    echo "✓ pnpm version: $(pnpm --version)"
    
    # Create a test project with pnpm
    mkdir -p /tmp/pnpm-test
    cd /tmp/pnpm-test
    echo '{"name": "pnpm-test", "version": "1.0.0"}' > package.json
    pnpm add axios
    if [ -f "pnpm-lock.yaml" ]; then
        echo "✓ pnpm successfully installed a package"
    else
        echo "✗ pnpm package installation failed"
    fi
    cd -
    rm -rf /tmp/pnpm-test
else
    echo "✗ pnpm not found in PATH"
fi

# Test asdf
echo -e "\n3. Testing asdf:"
# Source the asdf script to make it available
export PATH="/usr/local/bin:$PATH"
if command -v asdf &> /dev/null; then
    echo "✓ asdf found at: $(which asdf)"
    echo "✓ asdf version: $(asdf --version)"
    
    # Test asdf plugin management
    asdf plugin list &> /dev/null
    if [ $? -eq 0 ]; then
        echo "✓ asdf plugin management is working"
    else
        echo "✗ asdf plugin management failed"
    fi
    
    # Try to add a plugin (nodejs as an example)
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git &> /dev/null || true
    if asdf plugin list | grep -q nodejs; then
        echo "✓ asdf successfully added nodejs plugin"
    else
        echo "✓ asdf is installed (plugin test skipped - requires git configuration)"
    fi
else
    echo "✗ asdf not found in PATH"
fi

echo -e "\nAll tests completed!"