from fastapi import FastAPI, Depends, HTTPException
import os
import psycopg2
from psycopg2.pool import SimpleConnectionPool
from pydantic import BaseModel

app = FastAPI()

# Environment variables for configuration
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "postgres")
DB_NAME = os.getenv("DB_NAME", "demo")
CLUSTER_NAME = os.getenv("CLUSTER_NAME", "unknown-cluster")
REGION = os.getenv("REGION", "unknown-region")

# Connection pool
db_pool = None

class Message(BaseModel):
    content: str

def get_db():
    if db_pool:
        conn = db_pool.getconn()
        try:
            yield conn
        finally:
            db_pool.putconn(conn)
    else:
        yield None

@app.on_event("startup")
def startup():
    global db_pool
    try:
        db_pool = SimpleConnectionPool(1, 10, host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS)
        # Create table if it doesn't exist
        conn = db_pool.getconn()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                id SERIAL PRIMARY KEY,
                content TEXT NOT NULL,
                cluster VARCHAR(255),
                region VARCHAR(255)
            )
        """)
        conn.commit()
        cur.close()
        db_pool.putconn(conn)
        print("Database connected and initialized.")
    except Exception as e:
        print(f"Failed to connect to DB: {e}")

@app.on_event("shutdown")
def shutdown():
    if db_pool:
        db_pool.closeall()

@app.get("/status")
def read_status():
    return {
        "status": "ok",
        "cluster": CLUSTER_NAME,
        "region": REGION,
        "db_connected": db_pool is not None
    }

@app.post("/messages")
def create_message(msg: Message, conn=Depends(get_db)):
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection not available")
    
    try:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO messages (content, cluster, region) VALUES (%s, %s, %s) RETURNING id",
            (msg.content, CLUSTER_NAME, REGION)
        )
        msg_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        return {"id": msg_id, "content": msg.content, "cluster": CLUSTER_NAME, "region": REGION}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/messages")
def list_messages(conn=Depends(get_db)):
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection not available")
    
    try:
        cur = conn.cursor()
        cur.execute("SELECT id, content, cluster, region FROM messages ORDER BY id DESC LIMIT 10")
        rows = cur.fetchall()
        cur.close()
        return [{"id": r[0], "content": r[1], "cluster": r[2], "region": r[3]} for r in rows]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
