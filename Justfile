default:
    just -l

download:
    #!/usr/bin/env sh
    for country in $(grep -v "\#" countries.wanted); do
        aria2c -x 10 -d world -c https://download.geofabrik.de/$country-latest.osm.pbf
    done

filter:
    #!/usr/bin/env sh
    mkdir filtered/rail
    for country in $(grep -v "\#" countries.wanted); do
        BASE=$(basename $country)
        osmium tags-filter \
            --expressions=filter.params \
            world/$BASE-latest.osm.pbf \
            -o filtered/rail/$BASE-latest.osm.pbf \
            --overwrite
    done

# to decrease peak disk space, download+filter in one
downloadfilter:
    #!/usr/bin/env sh
    mkdir filtered/rail
    for country in $(grep -v "\#" countries.wanted); do
        BASE=$(basename $country)
        aria2c -x 10 -d world -c https://download.geofabrik.de/$country-latest.osm.pbf
        osmium tags-filter \
            --expressions=filter.params \
            world/$BASE-latest.osm.pbf \
            -o filtered/rail/$BASE-latest.osm.pbf \
            --overwrite
        rm world/$BASE-latest.osm.pbf
    done

combine:
    #!/usr/bin/env sh
    mkdir -p output/rail
    osmium merge filtered/rail/*.osm.pbf -o output/rail/combined.osm.pbf --overwrite

osrm:
    #!/usr/bin/env sh
    osrm-extract   output/rail/combined.osm.pbf -p rail.lua
    osrm-partition output/rail/combined.osm.pbf
    osrm-customize output/rail/combined.osm.pbf

all: download filter combine osrm
allsmall: downloadfilter combine osrm

clean:
    #!/usr/bin/env sh
    rm filtered/* output/* world/*

serve IP PORT:
    #!/usr/bin/env sh
    osrm-routed --algorithm mld output/rail/combined.osrm --ip {{IP}} --port {{PORT}}
