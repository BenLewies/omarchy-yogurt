import importlib.util
from pathlib import Path
import sqlite3
import tempfile
import unittest

SPEC=importlib.util.spec_from_file_location('yogurt_status',Path(__file__).resolve().parents[1]/'status.py')
module=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(module)

class StatusTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
    def tearDown(self):self.temp.cleanup()
    def database(self):
        c=sqlite3.connect(self.root/'yogurt.db')
        c.execute('create table meetings(id text,title text,state text,started_at integer,ended_at integer,duration_ms integer,transcription_state text,transcription_pending integer,trashed_at integer)')
        c.commit();return c
    def test_missing_database_is_not_created(self):
        self.assertFalse(module.snapshot(self.root)['available']);self.assertFalse((self.root/'yogurt.db').exists())
    def test_live_wal_metadata_and_no_transcript_access(self):
        c=self.database();c.execute('pragma journal_mode=WAL')
        c.execute('insert into meetings values(?,?,?,?,?,?,?,?,?)',('live','<img src="remote">','recording',1000,None,None,None,1,None));c.commit()
        result=module.snapshot(self.root)
        self.assertEqual(result['recording']['id'],'live');self.assertEqual(result['recording']['title'],'<img src="remote">');self.assertEqual(c.execute('select count(*) from meetings').fetchone()[0],1)
        c.close()
    def test_finished_duration_and_trash_filter(self):
        c=self.database()
        for i in range(5):c.execute('insert into meetings values(?,?,?,?,?,?,?,?,?)',(str(i),'Meeting','done',1000+i,61000+i,None,'done',0,None if i<4 else 90000))
        c.commit();c.close();result=module.snapshot(self.root)
        self.assertEqual(len(result['recent']),3);self.assertEqual(result['recent'][0]['id'],'3');self.assertEqual(result['recent'][0]['durationMs'],60000)
    def test_schema_drift_and_corruption_fail_closed(self):
        (self.root/'yogurt.db').write_text('not a database');self.assertFalse(module.snapshot(self.root)['available'])
    def test_titles_are_bounded(self):
        c=self.database();c.execute('insert into meetings values(?,?,?,?,?,?,?,?,?)',('1','x'*10000,'done',1000,2000,None,None,0,None));c.commit();c.close()
        self.assertEqual(len(module.snapshot(self.root)['recent'][0]['title']),160)
if __name__=='__main__':unittest.main()
