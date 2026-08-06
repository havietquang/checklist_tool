-- FIXTURE co tinh SAI 2.6: surrogate key MAX(ID)+ROW_NUMBER, thieu cot hieu luc SCD2
INSERT INTO ocb_datavault_dev_curated.tckh.CB_OU_DIM (OU_DIM_ID, OU_ID)
SELECT (SELECT MAX(OU_DIM_ID) FROM ocb_datavault_dev_curated.tckh.CB_OU_DIM)
           + ROW_NUMBER() OVER (ORDER BY h.branch_hashkey) AS OU_DIM_ID,
       h.branch_hashkey                                    AS OU_ID
FROM ocb_datavault_dev_cleaned.raw_vault.hub_branch h
WHERE h.source_event_date <= :DATADT;
