# Week 5 Reflection

## 1. Requirements in Tension

The main tension I noticed was between keeping the pipeline simple
and adding enough checks to catch problems early. More checks improve
confidence, but they also increase build time. I chose to keep linting,
testing, security auditing, and artifact publishing because a reliable
build is more important than saving a few minutes.

## 2. Explaining the Pipeline Technically

For Nia, I would say, "The pipeline checks the application before
making the package available." Technically, I would explain that Jenkins
runs linting, tests, and a security audit before archiving and publishing
the versioned artifact to Nexus. Both versions explain how problems are
caught before delivery, but the technical version names the stages and
tools involved.

## 3. Growing from Four to Forty Developers

I think the shared Jenkins pipeline would struggle first. More developers
mean more commits and builds competing for limited resources. I would
add build agents, control concurrency, and use clear branch and merge
rules. This would help the team run builds reliably without creating
long queues or conflicting changes.

