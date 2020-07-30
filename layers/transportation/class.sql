CREATE OR REPLACE FUNCTION brunnel(is_bridge bool, is_tunnel bool, is_ford bool) RETURNS text AS
$$
SELECT CASE
           WHEN is_bridge THEN 'bridge'
           WHEN is_tunnel THEN 'tunnel'
           WHEN is_ford THEN 'ford'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- The classes for highways are derived from the classes used in ClearTables
-- https://github.com/ClearTables/ClearTables/blob/master/transportation.lua
CREATE OR REPLACE FUNCTION highway_class(highway text, public_transport text, construction text) RETURNS text AS
$$
SELECT CASE
   WHEN highway IN ('motorway', 'motorway_link') THEN 'motorway'
   WHEN highway IN ('trunk', 'trunk_link') THEN 'trunk'
   WHEN highway IN ('primary', 'primary_link') THEN 'primary'
   WHEN highway IN ('secondary', 'secondary_link') THEN 'secondary'
   WHEN highway IN ('tertiary', 'tertiary_link') THEN 'tertiary'
   WHEN highway IN ('unclassified', 'residential', 'living_street', 'road') THEN 'minor'
   WHEN highway IN ('pedestrian', 'path', 'footway', 'cycleway', 'steps', 'bridleway', 'corridor') OR public_transport IN ('platform') THEN 'path'
   WHEN highway IN ('service', 'track', 'raceway') THEN highway
   WHEN highway = 'construction' THEN CASE
     WHEN construction IN ('motorway', 'motorway_link') THEN 'motorway_construction'
     WHEN construction IN ('trunk', 'trunk_link') THEN 'trunk_construction'
     WHEN construction IN ('primary', 'primary_link') THEN 'primary_construction'
     WHEN construction IN ('secondary', 'secondary_link') THEN 'secondary_construction'
     WHEN construction IN ('tertiary', 'tertiary_link') THEN 'tertiary_construction'
     WHEN construction = '' OR construction IN ('unclassified', 'residential', 'living_street', 'road') THEN 'minor_construction'
     WHEN construction IN ('pedestrian', 'path', 'footway', 'cycleway', 'steps', 'bridleway', 'corridor') OR public_transport IN ('platform') THEN 'path_construction'
     WHEN construction IN ('service', 'track', 'raceway') THEN CONCAT(highway, '_construction')
     ELSE NULL
   END
   ELSE NULL
END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;

-- The classes for railways are derived from the classes used in ClearTables
-- https://github.com/ClearTables/ClearTables/blob/master/transportation.lua
CREATE OR REPLACE FUNCTION railway_class(railway text) RETURNS text AS
$$
SELECT CASE
           WHEN railway IN ('rail', 'narrow_gauge', 'preserved', 'funicular') THEN 'rail'
           WHEN railway IN ('subway', 'light_rail', 'monorail', 'tram') THEN 'transit'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Limit service to only the most important values to ensure
-- we always know the values of service
CREATE OR REPLACE FUNCTION service_value(service text) RETURNS text AS
$$
SELECT CASE
           WHEN service IN ('spur', 'yard', 'siding', 'crossover', 'driveway', 'alley', 'parking_aisle') THEN service
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Limit surface to only the most important values to ensure
-- we always know the values of surface
CREATE OR REPLACE FUNCTION surface_value(surface text) RETURNS text AS
$$
SELECT CASE
           WHEN surface IN ('paved', 'asphalt', 'cobblestone', 'concrete', 'concrete:lanes', 'concrete:plates', 'metal',
                            'paving_stones', 'sett', 'unhewn_cobblestone', 'wood') THEN 'paved'
           WHEN surface IN ('unpaved', 'compacted', 'dirt', 'earth', 'fine_gravel', 'grass', 'grass_paver', 'gravel',
                            'gravel_turf', 'ground', 'ice', 'mud', 'pebblestone', 'salt', 'sand', 'snow', 'woodchips')
               THEN 'unpaved'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;
