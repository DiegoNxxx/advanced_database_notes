-- exercise 1

from sqlalchemy import (
    create_engine, Column, Integer, String,
    Text, ForeignKey, DateTime, func
)
from sqlalchemy.orm import declarative_base, relationship, Session

Base = declarative_base()

class Team(Base):
    __tablename__ = "teams"

    id = Column(Integer, primary_key=True)
    name = Column(String(50), nullable=False, unique=True)
    description = Column(String(200))
    created_at = Column(DateTime, server_default=func.current_timestamp())

    users = relationship("User", back_populates="team")

    def __repr__(self):
        return f"<Team(id={self.id}, name='{self.name}')>"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    username = Column(String(50), nullable=False, unique=True)
    email = Column(String(100), nullable=False)
    full_name = Column(String(100))
    team_id = Column(Integer, ForeignKey("teams.id"))
    created_at = Column(DateTime, server_default=func.current_timestamp())

    team = relationship("Team", back_populates="users")

    tasks = relationship(
        "Task",
        back_populates="assignee"
    )

    comments = relationship(
        "Comment",
        back_populates="user"
    )

    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}')>"


class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True)
    title = Column(String(200), nullable=False)
    description = Column(String(1000))
    status = Column(String(20), default="open")
    assigned_to = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, server_default=func.current_timestamp())
    updated_at = Column(DateTime, onupdate=func.current_timestamp())

    assignee = relationship(
        "User",
        back_populates="tasks"
    )

    comments = relationship(
        "Comment",
        back_populates="task",
        cascade="all, delete"
    )

    def __repr__(self):
        return f"<Task(id={self.id}, title='{self.title}', status='{self.status}')>"


class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)

    task_id = Column(
        Integer,
        ForeignKey("tasks.id"),
        nullable=False
    )

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    content = Column(Text, nullable=False)

    created_at = Column(
        DateTime,
        server_default=func.current_timestamp()
    )

    task = relationship(
        "Task",
        back_populates="comments"
    )

    user = relationship(
        "User",
        back_populates="comments"
    )

    def __repr__(self):
        return f"<Comment(id={self.id})>"


print("✅ Models defined: Team, User, Task, Comment")

1. What relationships should `Comment` have?
- With Task and User.
2. Should `Task` have a `comments` relationship?
- Yes, because one task can have many comments.
3. What should happen to comments when a task is deleted?
- The comments should also be deleted.



-- exercise 2

# Generate migration from models vs current database state
command.revision(
    alembic_cfg,
    autogenerate=True,
    message='add comments table'
)

# Show what was generated
import glob

migration_files = sorted(
    glob.glob('/content/alembic/versions/*.py')
)

print('Generated migrations:')

for f in migration_files:
    print(f'  {f}')

# Read and display the latest migration
latest = migration_files[-1]

with open(latest) as f:
    content = f.read()

print(content)

command.upgrade(alembic_cfg, 'head')

print('✅ Migration applied!')

1. What does `upgrade()` do?
- The comments should also be deleted.

2. What does `downgrade()` do?
- The comments should also be deleted.

3. What happens if you downgrade this migration?
- The comments should also be deleted.


-- exercise 3

with Session(engine) as session:

    devops = Team(
        name="DevOps",
        description="Infrastructure team"
    )

    session.add(devops)
    session.commit()

    diana = User(
        username="diana_ops",
        email="diana@example.com",
        full_name="Diana Ops",
        team=devops
    )

    session.add(diana)
    session.commit()

    task1 = Task(
        title="Setup CI/CD",
        status="open",
        assignee=diana
    )

    task2 = Task(
        title="Docker cleanup",
        status="open",
        assignee=diana
    )

    task3 = Task(
        title="Remove old logs",
        status="open",
        assignee=diana
    )

    session.add_all([task1, task2, task3])
    session.commit()

    print("Task count:", session.query(Task).count())

    task1.status = "closed"

    session.commit()

    session.delete(task3)

    session.commit()

    print("✅ CRUD operations completed!")


-- exercise 4

# Rollback one migration
command.downgrade(alembic_cfg, '-1')

print('✅ Downgraded by 1. New columns removed.')

1. What happens to the column?
- The comments should also be deleted.

2. What happens to the data?
- The comments should also be deleted.


-- exercise 5

1. Why use ORM instead of raw SQL?
- Because it is easier to work with Python objects.

2. Why use migrations?
- To manage database changes safely.

3. When would you rollback?
- When a migration causes problems.

4. Difference between `add()` and `commit()`?
- `add()` prepares changes, `commit()` saves them.

5. Why are relationships useful?
- They make related data easier to access.