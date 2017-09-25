UPDATE SilverStripe_Lessons_Property SET AvailableStart = FROM_UNIXTIME(
        UNIX_TIMESTAMP(NOW()) + FLOOR(0 + (RAND() * 31536000))
);
UPDATE SilverStripe_Lessons_Property SET AvailableEnd = FROM_UNIXTIME(
        UNIX_TIMESTAMP(AvailableStart) + FLOOR(1 + (RAND() * 1209600))
);
