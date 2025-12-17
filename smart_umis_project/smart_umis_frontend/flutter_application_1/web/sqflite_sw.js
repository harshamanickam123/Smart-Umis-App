importScripts("https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/sql-wasm.js");

const _CHANNEL_NAME = 'sqflite';

let db;

self.addEventListener('message', async (event) => {
  const { id, method, args } = event.data;
  
  try {
    let result;
    
    switch(method) {
      case 'openDatabase':
        const SQL = await initSqlJs({
          locateFile: file => `https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/${file}`
        });
        db = new SQL.Database();
        result = { id };
        break;
        
      case 'execute':
        db.run(args.sql);
        result = { id };
        break;
        
      case 'insert':
        db.run(args.sql, args.arguments);
        result = { id, result: db.exec("SELECT last_insert_rowid()")[0].values[0][0] };
        break;
        
      case 'query':
        const queryResult = db.exec(args.sql, args.arguments);
        result = { id, result: queryResult };
        break;
        
      case 'update':
        db.run(args.sql, args.arguments);
        result = { id, result: db.getRowsModified() };
        break;
        
      default:
        result = { id, error: 'Unknown method' };
    }
    
    self.postMessage(result);
  } catch (error) {
    self.postMessage({ id, error: error.message });
  }
});