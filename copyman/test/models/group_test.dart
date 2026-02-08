import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/models/group.dart';

void main() {
  group('Group.fromMap', () {
    test('deserializes all fields', () {
      final map = {
        'id': 5,
        'name': 'Work',
        'color': '#FF5722',
        'created_at': 100,
        'updated_at': 200,
      };
      final g = Group.fromMap(map);
      expect(g.id, 5);
      expect(g.name, 'Work');
      expect(g.color, '#FF5722');
      expect(g.createdAt, 100);
      expect(g.updatedAt, 200);
    });

    test('falls back to default color when null', () {
      final map = {
        'id': 1,
        'name': 'Test',
        'color': null,
        'created_at': 0,
        'updated_at': 0,
      };
      final g = Group.fromMap(map);
      expect(g.color, '#4CAF50');
    });
  });

  group('Group.toFlutterColor', () {
    test('parses #4CAF50 to correct Color', () {
      final g = Group(id: 1, name: 'g', color: '#4CAF50', createdAt: 0, updatedAt: 0);
      expect(g.toFlutterColor(), const Color(0xFF4CAF50));
    });

    test('parses #9E9E9E correctly', () {
      final g = Group(id: 1, name: 'g', color: '#9E9E9E', createdAt: 0, updatedAt: 0);
      expect(g.toFlutterColor(), const Color(0xFF9E9E9E));
    });
  });

  group('Group.copyWith', () {
    final original = Group(id: 1, name: 'Original', color: '#AAAAAA', createdAt: 10, updatedAt: 20);

    test('overrides only specified fields, preserves rest', () {
      final copy = original.copyWith(name: 'Updated');
      expect(copy.id, 1);
      expect(copy.name, 'Updated');
      expect(copy.color, '#AAAAAA');
      expect(copy.createdAt, 10);
      expect(copy.updatedAt, 20);
    });

    test('can override multiple fields', () {
      final copy = original.copyWith(id: 99, color: '#FFFFFF', updatedAt: 999);
      expect(copy.id, 99);
      expect(copy.name, 'Original');
      expect(copy.color, '#FFFFFF');
      expect(copy.createdAt, 10);
      expect(copy.updatedAt, 999);
    });
  });
}
