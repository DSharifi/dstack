#!/bin/bash

set -e

export DSTACK_SIMULATOR_ENDPOINT=$(realpath simulator/dstack.sock)
export TAPPD_SIMULATOR_ENDPOINT=$(realpath simulator/tappd.sock)

pushd simulator
./build.sh
./dstack-simulator >/dev/null 2>&1 &
SIMULATOR_PID=$!
trap "kill $SIMULATOR_PID 2>/dev/null || true" EXIT
popd

pushd rust/
cargo test -- --show-output
cargo run --example tappd_client_usage
cargo run --example dstack_client_usage
popd

pushd go/
go test -v ./dstack
DSTACK_SIMULATOR_ENDPOINT=$TAPPD_SIMULATOR_ENDPOINT go test -v ./tappd
popd

pushd python/
if [ ! -d .venv ]; then
    python -m venv .venv
fi
source .venv/bin/activate
pip install -e .
pip install pytest pytest-asyncio evidence-api web3 solders
pytest
popd

pushd js/
npm install
npm run test -- --run
popd
