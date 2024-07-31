'use client'

import { useEffect, useState } from 'react'
import { Typography, Row, Col, Space, Button, Card } from 'antd'
import { FundOutlined } from '@ant-design/icons'
const { Title, Paragraph } = Typography
import { useSnackbar } from 'notistack'
import { useRouter, useParams } from 'next/navigation'
import { PageLayout } from '../components/page.layout'

export default function InvestmentStrategiesPage() {
  const router = useRouter()
  const { enqueueSnackbar } = useSnackbar()

  const [investmentStrategies, setInvestmentStrategies] = useState<any[]>([])

  useEffect(() => {
    

    // Adding demo data for investment strategies
    const demoData = [
      {
        id: '1',
        name: 'Invest Strategy 1',
        description: 'Invest in a diversified portfolio of real estate properties.'
      },
      {
        id: '2',
        name: 'Invest Strategy 2',
        description: 'Invest in promising tech startups with high growth potential.'
      },
      {
        id: '3',
         name: 'Invest Strategy 1',
        description: 'Invest in renewable energy projects and companies.'
      }
    ]
    setInvestmentStrategies(demoData)
  }, [])

  const handleInvest = (strategyId: string) => {
    // Implement invest functionality
  }

  const handleWithdraw = (strategyId: string) => {
    // Implement withdraw functionality
  }

  const handleNavigateToStrategy = (strategyId: string) => {
    // router.push(`/investment-strategy/${strategyId}`)
  }

  return (
    <PageLayout layout="full-width">
      <Row justify="center">
        <Col xs={24} sm={20} md={16} lg={12}>
          <Title level={2}>Investment Strategies</Title>
          <Paragraph>
            Use your borrowed funds to invest in available investment strategy pools.
          </Paragraph>
          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            {investmentStrategies.length > 0 ? (
              investmentStrategies.map(strategy => (
                <Card
                  key={strategy.id}
                  title={strategy.name}
                  onClick={() => handleNavigateToStrategy(strategy.id)}
                  hoverable
                >
                  <Paragraph>{strategy.description}</Paragraph>
                  <Space>
                    <Button type="primary" onClick={() => handleInvest(strategy.id)}>Invest</Button>
                    <Button onClick={() => handleWithdraw(strategy.id)}>Withdraw</Button>
                  </Space>
                </Card>
              ))
            ) : (
              <Paragraph>No investment strategies available at the moment.</Paragraph>
            )}
          </Space>
        </Col>
      </Row>
    </PageLayout>
  )
}
