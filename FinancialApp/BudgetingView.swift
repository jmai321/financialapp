import SwiftUI

struct BudgetingView: View {
    @State private var isStudent = false
    @State private var isInDebt = false
    @State private var income: String = ""

    var categories: [(String, Double)] {
        let incomeValue = Double(income) ?? 0.0
        var categories: [(String, Double)]
        
        if isStudent && isInDebt {
            categories = [
                ("Basic Needs", 0.40 * incomeValue),
                ("Debt Repayment", 0.20 * incomeValue),
                ("Savings", 0.10 * incomeValue),
                ("Discretionary Spending", 0.20 * incomeValue),
                ("Education-related Expenses", 0.10 * incomeValue)
            ]
        } else if isStudent && !isInDebt {
            categories = [
                ("Basic Needs", 0.50 * incomeValue),
                ("Savings", 0.20 * incomeValue),
                ("Discretionary Spending", 0.20 * incomeValue),
                ("Education-related Expenses", 0.10 * incomeValue)
            ]
        } else if !isStudent && isInDebt {
            categories = [
                ("Basic Needs", 0.40 * incomeValue),
                ("Debt Repayment", 0.20 * incomeValue),
                ("Savings and Investments", 0.20 * incomeValue),
                ("Discretionary Spending", 0.15 * incomeValue),
                ("Insurance and Risk Management", 0.05 * incomeValue)
            ]
        } else {
            categories = [
                ("Basic Needs", 0.40 * incomeValue),
                ("Savings and Investments", 0.30 * incomeValue),
                ("Discretionary Spending", 0.20 * incomeValue),
                ("Insurance and Risk Management", 0.10 * incomeValue)
            ]
        }
        
        return categories
    }

    var body: some View {
        VStack {
            Text("Budgeting")
                .font(.largeTitle)
                .bold()
                .padding(.top, 20)

            VStack {
                TextField("Enter your monthly income", text: $income)
                    .keyboardType(.decimalPad)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Toggle("Are you a student?", isOn: $isStudent)
                Toggle("Are you in debt?", isOn: $isInDebt)
            }
            .padding(.top, 20)

            if let incomeValue = Double(income), incomeValue > 0 {
                PieChartView(categories: categories)
                    .frame(height: 300)

                ScrollView {
                    VStack {
                        ForEach(categories.indices, id: \.self) { index in
                            let category = categories[index]
                            HStack {
                                ColorIndicatorView(color: Color.palette[index % Color.palette.count])
                                    .frame(width: 20, height: 20)
                                    .cornerRadius(5)
                                Text(category.0)
                                Spacer()
                                Text("$\(Int(category.1))")
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            } else {
            }
        }
        .navigationTitle("Budgeting")
    }
}

struct PieChartView: View {
    let categories: [(String, Double)]

    var body: some View {
        GeometryReader { geometry in
            let totalIncome = categories.reduce(0) { $0 + $1.1 }
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let radius = min(centerX, centerY)

            ZStack {
                ForEach(0..<categories.count, id: \.self) { index in
                    let startAngle = angle(at: index, totalIncome: totalIncome)
                    let endAngle = angle(at: index + 1, totalIncome: totalIncome)

                    PieSlice(startAngle: startAngle, endAngle: endAngle)
                        .fill(Color.palette[index % Color.palette.count])
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(
                            Text("\(Int(categories[index].1))")
                                .position(position(for: startAngle, endAngle, center: CGPoint(x: centerX, y: centerY), radius: radius))
                                .foregroundColor(.white)
                                .font(.caption)
                        )
                }
            }
        }
    }

    private func angle(at index: Int, totalIncome: Double) -> Angle {
        let values = categories.map { $0.1 }
        let percentage = values.prefix(index).reduce(0, +) / totalIncome
        return .degrees(percentage * 360)
    }

    private func position(for startAngle: Angle, _ endAngle: Angle, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = startAngle + (endAngle - startAngle) / 2
        let x = center.x + radius * 0.5 * CGFloat(cos(angle.radians))
        let y = center.y + radius * 0.5 * CGFloat(sin(angle.radians))
        return CGPoint(x: x, y: y)
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()

        return path
    }
}

struct ColorIndicatorView: View {
    let color: Color
    
    var body: some View {
        Rectangle()
            .fill(color)
    }
}

extension Color {
    static let palette: [Color] = [
        .purple, .pink, .blue, .green, .orange, .yellow
    ]
}

struct BudgetingView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetingView()
    }
}
