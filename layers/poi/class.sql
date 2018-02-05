CREATE OR REPLACE FUNCTION poi_class_rank(class TEXT)
RETURNS INT AS $$
    SELECT CASE class
        WHEN 'hospital' THEN 20
        WHEN 'fire_station' THEN 30
        WHEN 'bicycle' THEN 35
        WHEN 'railway' THEN 40
        WHEN 'bus' THEN 50
        WHEN 'sport' THEN 65
        WHEN 'attraction' THEN 70
        WHEN 'harbor' THEN 75
        WHEN 'college' THEN 80
        WHEN 'school' THEN 85
        WHEN 'stadium' THEN 90
        WHEN 'zoo' THEN 95
        WHEN 'town_hall' THEN 100
        WHEN 'campsite' THEN 110
        WHEN 'cemetery' THEN 115
        WHEN 'park' THEN 120
        WHEN 'library' THEN 130
        WHEN 'police' THEN 135
        WHEN 'post' THEN 140
        WHEN 'golf' THEN 150
        WHEN 'shop' THEN 400
        WHEN 'grocery' THEN 500
        WHEN 'fast_food' THEN 600
        WHEN 'clothing_store' THEN 700
        WHEN 'restaurant' THEN 750
        WHEN 'bar' THEN 800
        ELSE 1000
    END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION poi_class(subclass TEXT, mapping_key TEXT)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN subclass IN ('accessories','antiques','beauty','bed','boutique','camera','carpet','charity','chemist','chocolate','computer','confectionery','convenience','copyshop','cosmetics','doityourself','erotic','electronics','fabric','florist','furniture','video_games','video','general','gift','hardware','hearing_aids','hifi','interior_decoration','jewelry','kiosk','lamps','mall','massage','mobile_phone','newsagent','optician','outdoor','perfumery','perfume','pet','photo','second_hand','shoes','stationery','tailor','tattoo','ticket','tobacco','toys','travel_agency','watches','weapons','wholesale', 'bank', 'bureau_de_change', 'casino', 'cinema') THEN 'shop'
        WHEN subclass IN ('townhall','public_building','courthouse','community_centre', 'embassy') THEN 'town_hall'
        WHEN subclass IN ('golf','golf_course','miniature_golf') THEN 'golf'
        WHEN subclass IN ('fast_food','food_court') THEN 'fast_food'
        WHEN subclass IN ('park','bbq', 'garden_centre') THEN 'park'
        WHEN subclass IN ('bus_stop','bus_station') THEN 'bus'
        WHEN (subclass='station' AND mapping_key = 'railway') OR subclass IN ('halt', 'tram_stop', 'subway') THEN 'railway'
        WHEN (subclass='station' AND mapping_key = 'aerialway') THEN 'aerialway'
        WHEN subclass IN ('camp_site','caravan_site') THEN 'campsite'
        WHEN subclass IN ('laundry','dry_cleaning') THEN 'laundry'
        WHEN subclass IN ('supermarket','deli','delicatessen','department_store','greengrocer','marketplace') THEN 'grocery'
        WHEN subclass IN ('books','library') THEN 'library'
        WHEN subclass IN ('university','college') THEN 'college'
        WHEN subclass IN ('hotel','motel','bed_and_breakfast','guest_house','hostel','chalet','alpine_hut','camp_site') THEN 'lodging'
        WHEN subclass IN ('chocolate','confectionery', 'ice_cream') THEN 'ice_cream'
        WHEN subclass IN ('post_box','post_office') THEN 'post'
        WHEN subclass IN ('cafe', 'coffee') THEN 'cafe'
        WHEN subclass IN ('school','kindergarten') THEN 'school'
        WHEN subclass IN ('alcohol','beverages','wine', 'nightclub') THEN 'alcohol_shop'
        WHEN subclass IN ('bar','nightclub') THEN 'bar'
        WHEN subclass IN ('marina','dock', 'boat_rental', 'boat_sharing', 'ferry_terminal') THEN 'harbor'
        WHEN subclass IN ('car','car_repair','taxi', 'fuel', 'parking', 'car_wash', 'car_rental', 'charging_station', 'parking_space') THEN 'car'
        WHEN subclass IN ('hospital','nursing_home', 'doctors', 'clinic', 'dentist', 'pharmacy', 'veterinary') THEN 'hospital'
        WHEN subclass IN ('grave_yard','cemetery') THEN 'cemetery'
        WHEN subclass IN ('attraction','viewpoint') THEN 'attraction'
        WHEN subclass IN ('biergarten','pub') THEN 'beer'
        WHEN subclass IN ('music','musical_instrument') THEN 'music'
        WHEN subclass IN ('american_football','stadium','soccer','pitch') THEN 'stadium'
        WHEN subclass IN ('antiques','art','artwork','gallery','arts_centre', 'theatre') THEN 'art_gallery'
        WHEN subclass IN ('bag','clothes') THEN 'clothing_store'
        WHEN subclass IN ('swimming_area','swimming') THEN 'swimming'
        WHEN subclass IN ('castle','ruins') THEN 'castle'
        WHEN subclass IN ('restaurant', 'drinking_water') THEN 'restaurant'
        WHEN subclass IN ('dive_centre', 'sports', 'dojo') THEN 'sport'
        WHEN subclass IN ('bicycle', 'bicycle_parking', 'bicycle_rental', 'motorcycle', 'motorcycle_parking') THEN 'bicycle'
        WHEN subclass IN ('firestation', 'fire_station') THEN 'fire_station'
        ELSE subclass
    END;
$$ LANGUAGE SQL IMMUTABLE;
