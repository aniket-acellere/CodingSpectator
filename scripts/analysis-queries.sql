--Compute the set of all captured refactoring ID's.
--CREATE TABLE "PUBLIC"."RefactoringIDs" ("id" varchar(1000));

--INSERT INTO "PUBLIC"."RefactoringIDs" ("id")
--SELECT "PUBLIC"."EclipseRefactorings"."id" FROM "PUBLIC"."EclipseRefactorings"
--UNION 
--SELECT "PUBLIC"."PerformedRefactorings"."id" FROM "PUBLIC"."PerformedRefactorings"
--UNION 
--SELECT "PUBLIC"."CancelledRefactorings"."id" FROM "PUBLIC"."CancelledRefactorings"
--UNION 
--SELECT "PUBLIC"."UnavailableRefactorings"."id" FROM "PUBLIC"."UnavailableRefactorings";

--Compute the number of each kind of refactoring invocation per refactoring ID for all users.
--SELECT
--"PUBLIC"."RefactoringIDs"."id",
--"PUBLIC"."EclipseRefactorings"."count" AS "ECLIPSE_COUNT",
--"PUBLIC"."PerformedRefactorings"."count" AS "PERFORMED_COUNT",
--"PUBLIC"."CancelledRefactorings"."count"  AS "CANCELLED_COUNT",
--"PUBLIC"."UnavailableRefactorings"."count" AS "UNAVAILABLE_COUNT" FROM
--"PUBLIC"."RefactoringIDs"
--FULL OUTER JOIN "PUBLIC"."EclipseRefactorings" ON ("PUBLIC"."RefactoringIDs"."id" = "PUBLIC"."EclipseRefactorings"."id")
--FULL OUTER JOIN "PUBLIC"."PerformedRefactorings" ON ("PUBLIC"."RefactoringIDs"."id" = "PUBLIC"."PerformedRefactorings"."id")
--FULL OUTER JOIN "PUBLIC"."CancelledRefactorings" ON ("PUBLIC"."RefactoringIDs"."id" = "PUBLIC"."CancelledRefactorings"."id")
--FULL OUTER JOIN "PUBLIC"."UnavailableRefactorings" ON ("PUBLIC"."RefactoringIDs"."id" = "PUBLIC"."UnavailableRefactorings"."id");

--Compute the number of each kind of refactoring invocation per refactoring ID for all users.
DROP TABLE "PUBLIC"."REFACTORING_COUNTS" IF EXISTS;

CREATE TABLE "PUBLIC"."REFACTORING_COUNTS" (
  "REFACTORING_ID" VARCHAR(1000),
  "ECLIPSE_COUNT" INT,
  "PERFORMED_COUNT" INT,
  "CANCELLED_COUNT" INT,
  "UNAVAILABLE_COUNT" INT
);

INSERT INTO "PUBLIC"."REFACTORING_COUNTS" (
  "REFACTORING_ID",
  "ECLIPSE_COUNT",
  "PERFORMED_COUNT",
  "CANCELLED_COUNT",
  "UNAVAILABLE_COUNT"
)
SELECT
"PUBLIC"."ALL_DATA"."id" AS "REFACTORING_ID",
COUNT(CASE "PUBLIC"."ALL_DATA"."refactoring kind" WHEN 'ECLIPSE' THEN 1 ELSE NULL END) AS "ECLIPSE_COUNT",
COUNT(CASE "PUBLIC"."ALL_DATA"."refactoring kind" WHEN 'PERFORMED' THEN 1 ELSE NULL END) AS "PERFORMED_COUNT",
COUNT(CASE "PUBLIC"."ALL_DATA"."refactoring kind" WHEN 'CANCELLED' THEN 1 ELSE NULL END) AS "CANCELLED_COUNT",
COUNT(CASE "PUBLIC"."ALL_DATA"."refactoring kind" WHEN 'UNAVAILABLE' THEN 1 ELSE NULL END) AS "UNAVAILABLE_COUNT"
FROM "PUBLIC"."ALL_DATA"
WHERE "PUBLIC"."ALL_DATA"."id" <> ''
GROUP BY "PUBLIC"."ALL_DATA"."id" 
ORDER BY "PUBLIC"."ALL_DATA"."id"; 

* *DSV_TARGET_FILE=RefactoringCounts.csv

\x "PUBLIC"."REFACTORING_COUNTS"

--Compute the number of each kind of refactoring invocation per user.
DROP TABLE "PUBLIC"."REFACTORING_COUNTS_PER_USER" IF EXISTS;

CREATE TABLE "PUBLIC"."REFACTORING_COUNTS_PER_USER" (
  "USERNAME" VARCHAR(20),
  "ECLIPSE_COUNT" INT,
  "PERFORMED_COUNT" INT,
  "CANCELLED_COUNT" INT,
  "UNAVAILABLE_COUNT" INT
);

INSERT INTO "PUBLIC"."REFACTORING_COUNTS_PER_USER" (
  "USERNAME",
  "ECLIPSE_COUNT",
  "PERFORMED_COUNT",
  "CANCELLED_COUNT",
  "UNAVAILABLE_COUNT"
)
SELECT
"PUBLIC"."ALL_DATA"."username" AS "USERNAME",
COUNT(CASE "PUBLIC"."ALL_DATA"."refactoring kind" WHEN 'ECLIPSE' THEN 1 ELSE NULL END) AS "ECLIPSE_COUNT",
COUNT(CASE "PUBLIC"."ALL_DATA"."refactoring kind" WHEN 'PERFORMED' THEN 1 ELSE NULL END) AS "PERFORMED_COUNT",
COUNT(CASE "PUBLIC"."ALL_DATA"."refactoring kind" WHEN 'CANCELLED' THEN 1 ELSE NULL END) AS "CANCELLED_COUNT",
COUNT(CASE "PUBLIC"."ALL_DATA"."refactoring kind" WHEN 'UNAVAILABLE' THEN 1 ELSE NULL END) AS "UNAVAILABLE_COUNT"
FROM "PUBLIC"."ALL_DATA"
GROUP BY "PUBLIC"."ALL_DATA"."username" 
ORDER BY "PUBLIC"."ALL_DATA"."username"; 

* *DSV_TARGET_FILE=RefactoringCountsPerUser.csv

\x "PUBLIC"."REFACTORING_COUNTS_PER_USER"

--Compute the number of different kinds of status for every pair of refactoring ID and refactoring invocation kind.
DROP TABLE "PUBLIC"."STATUS_COUNTS_PER_REFACTORING" IF EXISTS;

CREATE TABLE "PUBLIC"."STATUS_COUNTS_PER_REFACTORING" (
  "REFACTORING_ID" VARCHAR(1000),
  "REFACTORING_KIND" VARCHAR(50),
  "OK_STATUS_COUNT" INT,
  "WARNING_STATUS_COUNT" INT,
  "ERROR_STATUS_COUNT" INT,
  "FATALERROR_STATUS_COUNT" INT,
  "OTHER_STATUS_COUNT" INT,
  "EMPTY_STATUS_COUNT" INT
);

INSERT INTO "PUBLIC"."STATUS_COUNTS_PER_REFACTORING" (
  "REFACTORING_ID",
  "REFACTORING_KIND",
  "OK_STATUS_COUNT",
  "WARNING_STATUS_COUNT",
  "ERROR_STATUS_COUNT",
  "FATALERROR_STATUS_COUNT",
  "OTHER_STATUS_COUNT",
  "EMPTY_STATUS_COUNT"
)
SELECT
"PUBLIC"."ALL_DATA"."id" AS "REFACTORING_ID",
"PUBLIC"."ALL_DATA"."refactoring kind" AS "REFACTORING_KIND",
COUNT(CASE "PUBLIC"."ALL_DATA"."status" WHEN LIKE '_OK%' THEN 1 ELSE NULL END) AS "OK_STATUS_COUNT",
COUNT(CASE "PUBLIC"."ALL_DATA"."status" WHEN LIKE '_WARNING%' THEN 1 ELSE NULL END) AS "WARNING_STATUS_COUNT",
COUNT(CASE "PUBLIC"."ALL_DATA"."status" WHEN LIKE '_ERROR%' THEN 1 ELSE NULL END) AS "ERROR_STATUS_COUNT",
COUNT(CASE "PUBLIC"."ALL_DATA"."status" WHEN LIKE '_FATALERROR%' THEN 1 ELSE NULL END) AS "FATALERROR_STATUS_COUNT",
COUNT(CASE "PUBLIC"."ALL_DATA"."status"
  WHEN LIKE '_OK%' THEN NULL
  WHEN LIKE '_WARNING%' THEN NULL
  WHEN LIKE '_ERROR%' THEN NULL
  WHEN LIKE '_FATALERROR%' THEN NULL
  WHEN LIKE '' THEN NULL
  ELSE 1 END) AS "OTHER_STATUS_COUNT",
COUNT(CASE "PUBLIC"."ALL_DATA"."status" WHEN '' THEN 1 ELSE NULL END) AS "EMPTY_STATUS_COUNT"
FROM "PUBLIC"."ALL_DATA"
WHERE "PUBLIC"."ALL_DATA"."id" <> ''
GROUP BY "PUBLIC"."ALL_DATA"."id", "PUBLIC"."ALL_DATA"."refactoring kind" 
ORDER BY "PUBLIC"."ALL_DATA"."id", "PUBLIC"."ALL_DATA"."refactoring kind";

* *DSV_TARGET_FILE=StatusCountsPerRefactoring.csv

\x "PUBLIC"."STATUS_COUNTS_PER_REFACTORING"

