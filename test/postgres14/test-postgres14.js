const { assert } = require('chai');

const { Client } = require('pg');

describe('postgres14', () => {
  describe('VACUUM', () => {
    const table = 'vac_test_table';
    const dataLen = 100;
    const deleteProportion = 0.99;

    let client;

    beforeEach(async () => {
      const client = new Client({
        user: 'odk',
        password: 'odk',
        database: 'odk',
      });
      await client.connect();
      await client.query(`
        DROP TABLE IF EXISTS ${table};
        CREATE TABLE ${table} (
          id SERIAL PRIMARY KEY,
          data CHAR(${dataLen})
        );
      `);
    });

    async function rowsExist(rows) {
      const batchSize = 10000;

      for(let i=rows; i>0; i-= batchSize) {
        const batch = new Array(batchSize);

        for(let j=batchSize-1; j>=0; --j) batch[j] = new String(i + ':' + j);

        await client.query(`
          INSERT INTO ${table} (data) SELECT JSONB_ARRAY_ELEMENTS_TEXT($1::JSONB)
        `, [ JSON.stringify(batch) ]);
      }
    }

    it('should succeed with ___ pages to update', async () => {
      // given
      await rowsExist(500);

      // when
      const res = await client.query('VACUUM');

      // then
      assert.equal(res, {
        TODO: true,
      });
    });

    it('should fail with ___ pages to update', async () => {
      // given
      await rowsExist(5000);

      // when
      const res = await client.query('VACUUM');

      // then
      assert.equal(res, {
        TODO: true,
      });
    });
  });
});
