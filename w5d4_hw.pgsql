
CREATE OR REPLACE FUNCTION ret_late_fee(_return_date TIMESTAMP WITHOUT TIME ZONE, _rental_date TIMESTAMP WITHOUT TIME ZONE)
RETURNS DECIMAL(5, 2)
LANGUAGE plpgsql
AS $$
DECLARE
    return_interval INTERVAL;
BEGIN
    return_interval := _return_date - _rental_date;
	raise notice '%',return_interval;
    IF return_interval > INTERVAL'7 Days' THEN
        RETURN 5.00::DECIMAL(5, 2);
    ELSE
        RETURN 0::DECIMAL(5, 2);
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE add_late_fee(_customer_id INTEGER, _payment_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    rental_info RECORD;
BEGIN

    SELECT rental.return_date, rental.rental_date
    INTO rental_info
    FROM payment
    INNER JOIN rental ON payment.rental_id = rental.rental_id
    WHERE payment.customer_id = _customer_id AND payment.payment_id = _payment_id;

    UPDATE payment
    SET late_fee = ret_late_fee(rental_info.return_date, rental_info.rental_date)
    WHERE payment.customer_id = _customer_id AND payment.payment_id = _payment_id;

    COMMIT;
END;
$$

CALL add_late_fee(333,20118)

---------------------------------------------------------------------

ALTER TABLE customer
ADD COLUMN is_platinum_member BOOL
SELECT * FROM customer

---------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE set_plat_mem()
LANGUAGE plpgsql
AS $$
BEGIN
	
	UPDATE customer
	SET is_platinum_member = TRUE
	WHERE customer_id IN(
		SELECT customer.customer_id
		FROM customer
		INNER JOIN payment ON payment.customer_id = customer.customer_id
		WHERE payment.customer_id = customer.customer_id
		GROUP BY customer.customer_id
		HAVING SUM(payment.amount) > 200
	);

    UPDATE customer
	SET is_platinum_member = FALSE
	WHERE customer_id IN(
		SELECT customer.customer_id
		FROM customer
		INNER JOIN payment ON payment.customer_id = customer.customer_id
		WHERE payment.customer_id = customer.customer_id
		GROUP BY customer.customer_id
		HAVING SUM(payment.amount) < 200
	);
		

    COMMIT;
END;
$$

CALL set_plat_mem()

SELECT * from customer where is_platinum_member = true

------- Ran 2 separate tests to verify only 2 customers with sum(amount) > 200 ---------------------
	

SELECT customer.customer_id,customer.first_name,customer.is_platinum_member
    FROM customer
    INNER JOIN payment ON payment.customer_id = customer.customer_id
    GROUP BY customer.customer_id
	
	
SELECT SUM(amount),customer_id 
from payment 
GROUP BY customer_id 
HAVING SUM(amount) > 200