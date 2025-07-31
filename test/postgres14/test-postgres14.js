const { assert } = require('chai');

const { Client } = require('pg');

describe('postgres14', () => {
  describe('VACUUM', () => {
    const table = 'vac_test_table';

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
          data INTEGER
        );
      `);
    });

    afterEach(done => {
      client?.end(done);
    });

    async function rowsExist(rows) {
      await client.query(`INSERT INTO ${table} (data) GENERATE_SERIES(1, $1)`, [ rows ]);
    }

    async function deleteRows() {
      await client.query(`DELETE FROM ${table} WHERE data % 2 = 0`);
    }

    async function vacuum() {
      console.log(`vac:`, await client.query(`VACUUM VERBOSE ${table}`));
    }

    it('should succeed with ___ pages to update', async () => {
      // given
      await rowsExist(500);
      // and
      await deleteRows();

      // when
      await vacuum();
    });

    it('should fail with ___ pages to update', async function() {
      this.timeout(100_000); // TODO make this double a reasonable run on CI

      // given
      await rowsExist(10_000); // TODO make this as low as possible to fail on CI
      // and
      await deleteRows();

      // when
      let caught;
      try {
        await vacuum();
      } catch(err) {
        caught = err;
      }

      assert.match(caught?.message, /^ERROR: could not resize shared memory segment ".*" to \d+ bytes: No space left on device$/);
    });
  });
});
