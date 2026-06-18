#!/usr/bin/env bash
set -e

echo "Checking lib/domain for illegal imports (Flutter / dart:io)..."

if grep -rn -E "import 'package:flutter/|import 'dart:io" lib/domain/; then
  echo "❌ Error: Found Flutter or dart:io imports in the domain layer. The domain layer must be pure Dart."
  exit 1
fi

echo "✅ Domain layer is clean."
