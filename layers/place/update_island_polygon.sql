DROP TRIGGER IF EXISTS trigger_flag ON osm_island_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON place_island_polygon.updates;

-- etldoc:  osm_island_polygon ->  osm_island_polygon
CREATE OR REPLACE FUNCTION update_osm_island_polygon() RETURNS void AS
$$
BEGIN
    UPDATE osm_island_polygon SET geometry=ST_PointOnSurface(ST_MakeValid(geometry)) WHERE ST_GeometryType(geometry) <> 'ST_Point';

    UPDATE osm_island_polygon
    SET tags = update_tags(tags, geometry)
    WHERE COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL;

    ANALYZE osm_island_polygon;
END;
$$ LANGUAGE plpgsql;

SELECT update_osm_island_polygon();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS place_island_polygon;

CREATE TABLE IF NOT EXISTS place_island_polygon.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION place_island_polygon.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_island_polygon.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION place_island_polygon.refresh() RETURNS trigger AS
$$
BEGIN
    RAISE LOG 'Refresh place_island_polygon';
    PERFORM update_osm_island_polygon();
    -- noinspection SqlWithoutWhere
    DELETE FROM place_island_polygon.updates;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_island_polygon
    FOR EACH STATEMENT
EXECUTE PROCEDURE place_island_polygon.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON place_island_polygon.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE place_island_polygon.refresh();
