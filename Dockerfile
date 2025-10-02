FROM nixos/nix

RUN nix-channel --update

WORKDIR /app

COPY countries.wanted Justfile rail.lua filter.params /app/

RUN nix-shell -p osmium-tool osrm-backend just aria2 --command 'just downloadfilter combine && rm -r filtered'