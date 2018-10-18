# Happening in a well-defined setting the Docker builds should be somewhat
# more reproducible than builds relying on the local workstation environment.
# Hence we're going to use the Docker build as the reference one.
# CI and local builds might be considered a second tier build optimizations.
# 
# docker build --tag mm2 .

FROM ubuntu:17.10

RUN \
    apt-get update &&\
    apt-get install -y git libcurl4-openssl-dev build-essential wget pax libleveldb-dev &&\
    # https://rust-lang-nursery.github.io/rust-bindgen/requirements.html#debian-based-linuxes
    apt-get install -y llvm-3.9-dev libclang-3.9-dev clang-3.9 &&\
    # openssl-sys requirements, cf. https://crates.io/crates/openssl-sys
    apt-get install -y pkg-config libssl-dev &&\
    apt-get clean

# Cmake 3.12.0 supports multi-platform -j option, it allows to use all cores for concurrent build to speed up it
RUN wget https://cmake.org/files/v3.12/cmake-3.12.0-Linux-x86_64.sh && \
    chmod +x cmake-3.12.0-Linux-x86_64.sh && \
    ./cmake-3.12.0-Linux-x86_64.sh --skip-license --exclude-subdir --prefix=/usr && \
    rm -rf cmake-3.12.0-Linux-x86_64.sh

# We need libsodium in order to build the `tox`.
# cf. https://download.libsodium.org/doc/installation
# On Ubuntu 17.10 artful the version is 1.0.13 which is a tad older than we want it to be.
RUN cd /tmp &&\
    wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.16.tar.gz &&\
    tar -xzf libsodium-1.0.16.tar.gz &&\
    cd libsodium-1.0.16 &&\
    ./configure &&\
    make &&\
    make install &&\
    cd .. &&\
    rm -rf libsodium-*

RUN \
    wget -O- https://sh.rustup.rs > /tmp/rustup-init.sh &&\
    sh /tmp/rustup-init.sh -y --default-toolchain stable &&\
    rm -f /tmp/rustup-init.sh

ENV PATH="/root/.cargo/bin:${PATH}"

# It seems that bindgen won't prettify without it:
RUN rustup component add rustfmt-preview

# Unlike the `COPY` command, the `RUN git clone` remains cached by Docker even if we change something locally.
# This allows us to more easily play with later Dockerfile steps by adding the `COPY` there.
RUN git clone --depth=1 -b mm2-dice https://github.com/artemii235/SuperNET.git /mm2

# Or with the "etomic" branch:
#RUN git clone --depth=1 -b etomic https://github.com/artemii235/SuperNET.git /mm2

# The number of Docker layers is limited AFAIK,
# so here we have a couple of configuration actions packed into a single step.
RUN cd /mm2 &&\
    # Put the version into the file, allowing us to easily use it from different Docker steps and from Rust.
    export MM_VERSION=`echo "$(git tag -l --points-at HEAD)"` &&\
    # If we're not in a CI-release environment then set the version to "UNKNOWN".
    if [ -z "$MM_VERSION" ]; then export MM_VERSION=UNKNOWN; fi &&\
    echo "MM_VERSION is $MM_VERSION" &&\
    echo -n "$MM_VERSION" > MM_VERSION

# Build just the dependencies first.
RUN cd /mm2 &&\
    cargo build --bin mm2-nop --features nop

# This will overwrite the Git version with the local one.
# Only needed when we're developing or changing something locally.
COPY . /mm2

# Build MM1 and MM2.
# Increased verbosity here allows us to see the MM1 CMake logs.
RUN cd /mm2 &&\
    cargo build -vv &&\
    mv target/debug/mm2 /usr/local/bin/marketmaker-mainnet &&\
    cargo test &&\
    cargo clean

CMD marketmaker-testnet
