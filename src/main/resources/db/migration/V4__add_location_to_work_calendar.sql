ALTER TABLE work_calendar
    ADD COLUMN custom_office_location_id BIGINT NULL,
    ADD CONSTRAINT fk_wc_office_location
        FOREIGN KEY (custom_office_location_id) REFERENCES office_location(id)
            ON DELETE SET NULL;
