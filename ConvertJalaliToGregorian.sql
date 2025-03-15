CREATE FUNCTION dbo.ConvertJalaliToGregorian
(
	 @y INT
	,@m INT
	,@d INT
)
RETURNS DATE
AS
BEGIN
    IF @y IS NULL OR @m IS NULL OR @d IS NULL
        RETURN NULL;
    IF @m < 1 OR @m > 12
        RETURN NULL;
    DECLARE @max_day INT;
    IF @m BETWEEN 1 AND 6
        SET @max_day = 31;
    ELSE IF @m BETWEEN 7 AND 11
        SET @max_day = 30;
    ELSE
    BEGIN
        DECLARE @mod33 INT = (@y - 1) % 33;
        DECLARE @is_leap BIT = CASE WHEN @mod33 IN (1,5,9,13,17,22,26,30) THEN 1 ELSE 0 END;
        SET @max_day = CASE WHEN @is_leap = 1 THEN 30 ELSE 29 END;
    END
    IF @d < 1 OR @d > @max_day
        RETURN NULL;
    DECLARE @days_in_current_year INT;
    IF @m <= 6
        SET @days_in_current_year = (@m - 1) * 31 + @d;
    ELSE IF @m <= 11
        SET @days_in_current_year = 6 * 31 + (@m - 7) * 30 + @d;
    ELSE
        SET @days_in_current_year = 6 * 31 + 5 * 30 + @d;
    DECLARE @number_of_full_cycles INT = (@y - 1) / 33;
    DECLARE @remainder INT = (@y - 1) % 33;
    DECLARE @leap_in_remainder INT = 
        CASE
            WHEN @remainder >= 30 THEN 8
            WHEN @remainder >= 26 THEN 7
            WHEN @remainder >= 22 THEN 6
            WHEN @remainder >= 17 THEN 5
            WHEN @remainder >= 13 THEN 4
            WHEN @remainder >= 9 THEN 3
            WHEN @remainder >= 5 THEN 2
            WHEN @remainder >= 1 THEN 1
            ELSE 0
        END;
    DECLARE @leap_years_count INT = @number_of_full_cycles * 8 + @leap_in_remainder;
    DECLARE @total_days INT = (@y - 1) * 365 + @leap_years_count + @days_in_current_year - 1;
    DECLARE @base_date DATETIME2 = DATEFROMPARTS(622, 3, 21);
    DECLARE @gregorian_date DATE = CAST(DATEADD(DAY, @total_days, @base_date) AS DATE);
    RETURN @gregorian_date;
END
