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
        name: 'RWA1/USDT',
        description: 'borrow USDT against your position in RWA1 real estate property.'
      },
      {
        id: '2',
        name: 'RWA2/USDT',
        description: 'borrow USDT against your position in RWA2 real estate property.'
      },
      {
        id: '3',
         name: 'RWA3/USDT',
         description: 'borrow USDT against your position in RWA3 real estate property.'
      },
      {
        id: '3',
         name: 'RWA4/USDT',
         description: 'borrow USDT against your position in RWA4 real estate property.'
      },
      {
        id: '3',
         name: 'RWA5/USDT',
         description: 'borrow USDT against your position in RWA5 real estate property.'
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
    // router.push(`/pools/${strategyId}`)
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
                    <Button type="primary" onClick={() => handleInvest(strategy.id)}>Lend</Button>
                    <Button onClick={() => handleWithdraw(strategy.id)}>Borrow</Button>
                    <Button onClick={() => handleWithdraw(strategy.id)}>Withdraw</Button>
                    <Button onClick={() => handleWithdraw(strategy.id)}>Repay</Button>
                  </Space>
                </Card>
              ))
            ) : (
              <Paragraph>No property pools available at the moment.</Paragraph>
            )}
          </Space>
        </Col>
      </Row>
    </PageLayout>
  )
}
