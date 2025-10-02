default:
    just -l

download:
    #!/usr/bin/env sh
    for country in $(grep -v "\#" countries.wanted); do
        aria2c -x 10 -d world -c https://download.geofabrik.de/$country-latest.osm.pbf
    done

filter:
    #!/usr/bin/env sh
    mkdir -p filtered
    for country in $(grep -v "\#" countries.wanted); do
        BASE=$(basename $country)
        osmium tags-filter \
            --expressions=filter.params \
            world/$BASE-latest.osm.pbf \
            -o filtered/$BASE-latest.osm.pbf \
            --overwrite
    done

# to decrease peak disk space, download+filter in one
downloadfilter:
    #!/usr/bin/env sh
    mkdir -p filtered
    for country in $(grep -v "\#" countries.wanted); do
        DL="world/$country.osm.pbf"
        OUT="filtered/$country.osm.pbf"
        # https://github.com/nixos/nix/issues/13523
        # TODO: do check certificate, when ^ is fixed
        aria2c --check-certificate=false -x 10 -c https://download.geofabrik.de/$country-latest.osm.pbf -o $DL
        osmium tags-filter \
            --expressions=filter.params \
            "$DL" \
            -o "$OUT" \
            --overwrite
        rm "$DL"
    done

combine:
    #!/usr/bin/env sh
    mkdir -p output
    osmium merge filtered/*.osm.pbf -o output/combined.osm.pbf

osrm:
    #!/usr/bin/env sh
    osrm-extract   output/combined.osm.pbf -p rail.lua
    osrm-partition output/combined.osm.pbf
    osrm-customize output/combined.osm.pbf

all: download filter combine osrm
allsmall: downloadfilter combine osrm

clean:
    #!/usr/bin/env sh
    rm filtered/* output/* world/*

serve IP PORT:
    #!/usr/bin/env sh
    osrm-routed --algorithm mld output/rail/combined.osrm --ip {{IP}} --port {{PORT}}
