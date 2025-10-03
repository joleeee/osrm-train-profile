FROM nixos/nix AS builder

RUN nix-channel --update

WORKDIR /app

COPY countries.wanted Justfile rail.lua filter.params /app/

RUN nix-shell -p osmium-tool osrm-backend just aria2 --command 'just downloadfilter combine && rm -r filtered'
RUN nix-shell -p osmium-tool osrm-backend just aria2 --command 'just osrm && rm output/combined.osm.pbf'


FROM nixos/nix AS runner
LABEL org.opencontainers.image.source=https://github.com/joleeee/osrm-train-profile

RUN nix-channel --update
RUN nix-env -iA nixpkgs.osrm-backend

COPY --from=builder /app/output/ /output

CMD [ "osrm-routed", "--algorithm=mld" , "/output/combined.osrm", "--ip=0.0.0.0", "--port=5001"]