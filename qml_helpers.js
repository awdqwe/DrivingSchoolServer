.pragma library

// 刷新表格：直接传入模型
function refreshTable(model, backend) {
    model.clear()

    // 从数据库获取最新数据
    var data = backend.getHistoryRecords()
    for (var i = 0; i < data.length; i++) {
        model.append(data[i]) // 塞入模型，界面自动渲染
    }
}

// 刷新图表：传入 QML 的 barSeries、xAxis、yAxis
function refreshChart(barSeries, xAxis, yAxis, backend) {
    var data = backend.getLeaderboard()

    // 清空已有柱子集合
    try {
        barSeries.clear()
    } catch (e) {
        console.log("refreshChart clear error: " + e)
    }

    var categories = []
    var maxVal = 0

    // 创建并填充一个新的柱子集合
    var barSet = barSeries.append("累计学时", [])
    try { barSet.color = "#3498db" } catch(e) {}

    for (var i = 0; i < data.length; i++) {
        categories.push(data[i].name)
        var val = data[i].total_seconds
        if (val > maxVal) maxVal = val
        barSet.append(val)
    }

    // 渲染 X 轴名字和动态调整 Y 轴最高点
    if (categories.length > 0) {
        xAxis.categories = categories
        yAxis.max = maxVal > 0 ? maxVal * 1.2 : 100
    } else {
        xAxis.categories = ["暂无打卡数据"]
    }
}
