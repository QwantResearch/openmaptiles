-- Compute the weight of an OSM POI, primarily this function relies on the
-- count of page views for the Wikipedia pages of this POI.
CREATE OR REPLACE FUNCTION poi_display_weight(
    name varchar,
    subclass varchar,
    mapping_key varchar,
    tags hstore
)
RETURNS REAL AS $$
    DECLARE
        max_views CONSTANT REAL := 1e6;
        min_views CONSTANT REAL := 50.;
        views_count real;
    BEGIN
        SELECT INTO views_count
            COALESCE(MAX(wm_stats.views)::real, 0)
            FROM wm_stats
            JOIN wd_sitelinks ON (wm_stats.title = wd_sitelinks.title
                              AND wm_stats.lang = wd_sitelinks.lang)
            WHERE wd_sitelinks.id = tags->'wikidata';
        RETURN CASE
            WHEN views_count > min_views THEN
                0.5 * (1 + LOG(LEAST(max_views, views_count)) / LOG(max_views))
            WHEN name = '' THEN
                0.0
            ELSE
                0.5 * (
                    1 - poi_class_rank(poi_class(subclass, mapping_key))::real / 2000
                )
        END;
    END
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION osm_hash_from_imposm(imposm_id bigint)
RETURNS bigint AS $$
    SELECT CASE
        WHEN imposm_id < -1e17 THEN (-imposm_id-1e17) * 10 + 4 -- Relation
        WHEN imposm_id < 0 THEN  (-imposm_id) * 10 + 1 -- Way
        ELSE imposm_id * 10 -- Node
    END::bigint;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION global_id_from_imposm(imposm_id bigint)
RETURNS TEXT AS $$
    SELECT CONCAT(
        'osm:',
        CASE WHEN imposm_id < -1e17 THEN CONCAT('relation:', -imposm_id-1e17)
             WHEN imposm_id < 0 THEN CONCAT('way:', -imposm_id)
             ELSE CONCAT('node:', imposm_id)
        END
    );
$$ LANGUAGE SQL IMMUTABLE;


-- etldoc: layer_poi[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_poi | <z12> z12 | <z13> z13 | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_poi(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, global_id text, geometry geometry, name text, name_en text, name_de text, tags hstore, class text, subclass text, agg_stop integer, layer integer, level integer, indoor integer, "rank" int, mapping_key text) AS $$
    SELECT osm_id_hash AS osm_id, global_id,
        geometry, NULLIF(name, '') AS name,
        COALESCE(NULLIF(name_en, ''), name) AS name_en,
        COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
        tags,
        poi_class(subclass, mapping_key) AS class,
        CASE
            WHEN subclass = 'information'
                THEN NULLIF(information, '')
            WHEN subclass = 'place_of_worship'
                THEN NULLIF(religion, '')
            WHEN subclass = 'pitch'
                THEN NULLIF(sport, '')
            ELSE subclass
        END AS subclass,
        agg_stop,
        NULLIF(layer, 0) AS layer,
        "level",
        CASE WHEN indoor=TRUE THEN 1 ELSE NULL END as indoor,
        row_number() OVER (
            PARTITION BY LabelGrid(geometry, 100 * pixel_width)
            ORDER BY poi_display_weight(name, subclass, mapping_key, tags) DESC
        )::int AS "rank"
    FROM (
        -- etldoc: osm_poi_point ->  layer_poi:z12
        -- etldoc: osm_poi_point ->  layer_poi:z13
        SELECT *,
            osm_hash_from_imposm(osm_id) AS osm_id_hash,
            global_id_from_imposm(osm_id) as global_id
        FROM osm_poi_point
            WHERE CASE WHEN bbox IS NULL THEN TRUE ELSE geometry && bbox END
                AND zoom_level BETWEEN 12 AND 13
                AND ((subclass='station' AND mapping_key = 'railway')
                    OR subclass IN ('halt', 'ferry_terminal'))
        UNION ALL

        -- etldoc: osm_poi_point ->  layer_poi:z14_
        SELECT *,
            osm_hash_from_imposm(osm_id) AS osm_id_hash,
            global_id_from_imposm(osm_id) as global_id
        FROM osm_poi_point
            WHERE CASE WHEN bbox IS NULL THEN TRUE ELSE geometry && bbox END
                AND zoom_level >= 14
                AND (name <> '' OR (subclass <> 'garden' AND subclass <> 'park'))

        UNION ALL
        -- etldoc: osm_poi_polygon ->  layer_poi:z12
        -- etldoc: osm_poi_polygon ->  layer_poi:z13
        SELECT *,
            NULL::INTEGER AS agg_stop,
            osm_hash_from_imposm(osm_id) AS osm_id_hash,
            global_id_from_imposm(osm_id) as global_id
        FROM osm_poi_polygon
            WHERE CASE WHEN bbox IS NULL THEN TRUE ELSE geometry && bbox END
                AND zoom_level BETWEEN 12 AND 13
                AND ((subclass='station' AND mapping_key = 'railway')
                    OR subclass IN ('halt', 'ferry_terminal'))

        UNION ALL
        -- etldoc: osm_poi_polygon ->  layer_poi:z14_
        SELECT *,
            NULL::INTEGER AS agg_stop,
            osm_hash_from_imposm(osm_id) AS osm_id_hash,
            global_id_from_imposm(osm_id) as global_id
        FROM osm_poi_polygon
            WHERE CASE WHEN bbox IS NULL THEN TRUE ELSE geometry && bbox END
                AND zoom_level >= 14
                AND (name <> '' OR (subclass <> 'garden' AND subclass <> 'park'))
        ) as poi_union
    ORDER BY "rank"
    ;
$$ LANGUAGE SQL IMMUTABLE;
