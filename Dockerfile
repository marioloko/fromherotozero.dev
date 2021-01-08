# Download Zola image.
FROM marioloko/zola:v0.12.2 as zola

# Build the static web site.
FROM debian:bullseye-slim as builder
COPY --from=zola /usr/bin/zola /usr/bin/zola
COPY . /workdir
WORKDIR /workdir
RUN /usr/bin/zola build

# Copy the built site in a new image.
FROM scratch
COPY --from=builder /workdir/public /public
