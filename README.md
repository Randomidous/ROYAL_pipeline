 Greetings fellow human!

   ROYAL_importBIDS is a pipeline tailored for import of NIRS data and
   subsequent saving in the current BIDS format (v1.9.0). This is a script
   in which you call this function multiple times, once for each
   individually recorded data file (or data set). It will write the
   corresponding sidecar JSON and TSV files for each data file.

   To execute this script, please specify all necessary data information,
   BIDS specifications and press run.


   Dependencies are:

   - ROYAL_* scripts:
       - *data2bids
       - *getOpto
       - *write_data

   - Toolboxes:
       - NIRS Toolbox
       - Homer3 with dependencies
       - SNIRF
       - FieldTrip

   See also:
   - ROYAL_data2bids
   - ROYAL_getOpto
   - ROYAL_write_data
