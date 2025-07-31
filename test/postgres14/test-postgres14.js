const { assert } = require('chai');

const { Client } = require('pg');

describe('postgres14', () => {
  describe('VACUUM', () => {
    const table = 'vac_test_table';
    const dataLen = 100;

    let client;

    beforeEach(async () => {
      client = new Client({
        host: '0.0.0.0',
        port: 5432,
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

    afterEach(done => {
      client?.end(done);
    });

    async function rowsExist(rows) {
      const batchSize = 10000;

      for(let i=rows; i>0; i-= batchSize) {
        const batch = new Array(batchSize);

        for(let j=batchSize-1; j>=0; --j) batch[j] = `${i}:${j}:`.padEnd(dataLen, '');

        await client.query(`
          INSERT INTO ${table} (data) SELECT JSONB_ARRAY_ELEMENTS_TEXT($1::JSONB)
        `, [ JSON.stringify(batch) ]);
      }
    }

    async function deleteRows(deleteProportion) {
      const { rows } = await client.query(`SELECT COUNT(*) FROM ${table}`);
      const { count } = rows[0];
      console.log('deleteRows()', 'count:', count);

      const batchSize = 100;

      for(let i=0; i<count; i+=batchSize) {
        const query = `DELETE FROM ${table} WHERE id>=$? AND id <= $?`;
        console.log('Deleteing:', query);
        await client.query(
          query,
          [ i, i + Math.floor(batchSize * deleteProportion) ],
        );
      }
    }

    it('should succeed with ___ pages to update', async () => {
      // given
      await rowsExist(500);
      // and
      await deleteRows(0.99);

      // when
      await client.query('VACUUM');
    });

    it('should fail with ___ pages to update', async function() {
      this.timeout(100_000);

      // given
      await rowsExist(5_000_000);
      // and
      await deleteRows(0.99);

      // when
      let caught;
      try {
        await client.query('VACUUM');
      } catch(err) {
        caught = err;
      }

      assert.equal(caught?.message, 'TODO should have thrown a particular error');
    });
  });
});
