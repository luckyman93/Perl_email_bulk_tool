FROM debian:bullseye-slim

# Install OS packages
RUN apt-get -q=2 -y update \
    && apt-get install -q=2 -y --no-install-recommends \
        libcatalyst-perl \
        libcatalyst-modules-perl \
        libdatetime-perl \
        libtext-csv-perl \
        libjson-perl \
        libwww-perl \
        starman \
    && rm -rf /var/lib/apt/lists/*
USER 33:33
WORKDIR /app

# COPY --chown=33:33  the application in
COPY --chown=33:33  lib    /app/lib
COPY --chown=33:33  root   /app/root
COPY --chown=33:33  script /app/script
COPY --chown=33:33  *.conf /app

# Setup the paths for the app
EXPOSE 3000

# Apply labels
# LABEL traefik.http.routers.marketing-sandbox-adwar.rule=Host(`marketing.sandbox.adwar.com`) traefik.http.routers.marketing-sandbox-adwar.entrypoints=websecure traefik.http.routers.marketing-sandbox-adwar.tls=true traefik.http.routers.marketing-sandbox-adwar.tls.certresolver=leresolver 
# LABEL traefik.http.middlewares.adwar-auth.basicauth.users=adwar:$$2y$$05$$Mo9AcHYj0eXKvZunFlG2guYQu1jYc2YWca5QbhDxtHeUZwtP70j5W traefik.http.routers.marketing-sandbox-adwar.middlewares=adwar-auth

# Run the "development" server by default

CMD /app/script/*_server.pl -k -d
