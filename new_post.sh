#!/bin/bash

source ~/.bashrc


# Get current date, year, and month
DATE=$(date +"%Y-%m-%d")
YEAR=$(date +"%Y")
MONTH=$(date +"%m")

echo "Enter the post title:"
read TITLE

echo "Enter the post slug:"
read SLUG

cat > _posts/$DATE-$SLUG.md <<EOL
---
layout: post
title: "$TITLE"
date: $DATE
excerpt: insert excerpt here
---

EOL
