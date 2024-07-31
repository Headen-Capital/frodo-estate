'use client'

import { useEffect, useState } from 'react'
import { Table, Typography, Spin, Row, Col } from 'antd'
import { HistoryOutlined } from '@ant-design/icons'
const { Title, Text } = Typography
import dayjs from 'dayjs'
import { useSnackbar } from 'notistack'
import { useRouter, useParams } from 'next/navigation'
import { PageLayout } from '../components/page.layout'

export default function TransactionHistoryPage() {
  const router = useRouter()
  const params = useParams<any>()
  
  const { enqueueSnackbar } = useSnackbar()

  const [loading, setLoading] = useState(true)
  const [transactions, setTransactions] = useState<any[]>([])

  useEffect(() => {
    setLoading(false)
  },[])
    
  const columns = [
    {
      title: 'Date',
      dataIndex: 'dateCreated',
      key: 'dateCreated',
      render: (text: string) => dayjs(text).format('YYYY-MM-DD HH:mm:ss'),
    },
    {
      title: 'Title',
      dataIndex: 'title',
      key: 'title',
    },
    {
      title: 'Message',
      dataIndex: 'message',
      key: 'message',
    },
    {
      title: 'Sender',
      dataIndex: 'senderName',
      key: 'senderName',
    },
  ]


  return (
    <PageLayout layout="full-width">
      <Row justify="center" style={{ marginBottom: '20px' }}>
        <Col>
          <Title level={2}>
            <HistoryOutlined /> Transaction History
          </Title>
          <Text>
            View your transaction history to keep track of your purchases and
            sales.
          </Text>
        </Col>
      </Row>
      {loading ? (
        <Row justify="center">
          <Col>
            <Spin size="large" />
          </Col>
        </Row>
      ) : (
        <Row justify="center">
          <Col span={24}>
            <Table
              dataSource={transactions}
              columns={columns}
              rowKey="id"
              pagination={{ pageSize: 10 }}
            />
          </Col>
        </Row>
      )}
    </PageLayout>
  )
}
