-- EXERCISE 1
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

UPDATE accounts SET balance = balance - 50 WHERE account_id = 3;
UPDATE accounts SET balance = balance + 50 WHERE account_id = 1;
COMMIT;

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

 

-- EXERCISE 2
UPDATE accounts SET balance = balance - 10000 WHERE account_id = 2;
UPDATE accounts SET balance = balance + 10000 WHERE account_id = 3;

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Bob only has 500

ROLLBACK;

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

 

-- EXERCISE 3
UPDATE accounts SET balance = balance + 25 WHERE account_id = 1;
SAVEPOINT my_checkpoint;

UPDATE accounts SET balance = balance - 25 WHERE account_id = 3;
ROLLBACK TO my_checkpoint;

UPDATE accounts SET balance = balance - 25 WHERE account_id = 2;
COMMIT;

 

-- EXERCISE 4
CREATE OR REPLACE PROCEDURE deposit_funds(
    p_account_id IN NUMBER,
    p_amount IN NUMBER
)
IS
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Amount must be greater than 0');
    END IF;

    UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_account_id;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

EXEC deposit_funds(3, 75);

 

-- EXERCISE 5

-- Question 1:
-- Both steps (a) and (b) need to be contained within the transaction since they involve data modifications. 
-- However, step (c) ought to remain external; failing to deliver a notification shouldn't trigger a rollback of the entire reservation process.

-- Question 2:
-- This approach leads to partial commits. Since the internal COMMIT finalizes the deposit immediately, that specific change becomes permanent even if the 
-- broader transaction encounters an error and fails to undo the remaining actions.

-- Question 3:
-- The calculate_copay() function is compatible with SELECT statements because it simply computes and returns data without side effects. 
-- Conversely, post_payment() is a procedure designed for data manipulation (DML); because it modifies records, it cannot be executed within a standard read-only query.