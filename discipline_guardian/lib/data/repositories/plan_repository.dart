import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../database/tables/plans_table.dart';
import '../models/plan_model.dart';

class PlanRepository {
  PlanRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  Future<List<PlanModel>> getPlans() async {
    final rows = await _databaseHelper.queryByCondition(
      PlansTable.tableName,
      orderBy: '${PlansTable.columnUpdatedAt} DESC',
    );
    return rows.map(PlanModel.fromMap).toList(growable: false);
  }

  Future<PlanModel?> getPlanById(String id) async {
    final row = await _databaseHelper.queryById(PlansTable.tableName, id);
    if (row == null) {
      return null;
    }
    return PlanModel.fromMap(row);
  }

  Future<PlanModel> createPlan({
    required String name,
    int durationDays = 100,
  }) async {
    final now = DateTime.now();
    final plan = PlanModel(
      id: _uuid.v4(),
      name: name,
      durationDays: durationDays,
      startDate: now,
      createdAt: now,
      updatedAt: now,
    );
    await _databaseHelper.insert(PlansTable.tableName, plan.toMap());
    return plan;
  }

  Future<void> updatePlan(PlanModel plan) async {
    await _databaseHelper.update(
      PlansTable.tableName,
      plan.toMap(),
      where: '${PlansTable.columnId} = ?',
      whereArgs: [plan.id],
    );
  }

  Future<void> deletePlan(String id) async {
    await _databaseHelper.delete(
      PlansTable.tableName,
      where: '${PlansTable.columnId} = ?',
      whereArgs: [id],
    );
  }
}
