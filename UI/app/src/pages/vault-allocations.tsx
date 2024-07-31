'use client'

import { useEffect, useState } from 'react'
import { Typography, Table, Button, Space, Modal } from 'antd'
import { DollarCircleOutlined, TransactionOutlined } from '@ant-design/icons'
const { Title, Text, Paragraph } = Typography
import dayjs from 'dayjs'
import { useSnackbar } from 'notistack'
import { useRouter, useParams } from 'next/navigation'
import { PageLayout } from '../components/page.layout'

export default function VaultAllocationsPage() {
  const router = useRouter()
  const params = useParams<any>()
  const { enqueueSnackbar } = useSnackbar()
  const [vaultAllocations, setVaultAllocations] = useState<any[]>([
    {
      id: 1,
      property: { id: 101, name: 'Property A' },
      allocation: 25,
      value: 50000,
    },
    {
      id: 2,
      property: { id: 102, name: 'Property B' },
      allocation: 50,
      value: 100000,
    },
  ])
  const [loading, setLoading] = useState(true)
  const [selectedProperty, setSelectedProperty] = useState<any | null>(null)
  const [isSellModalVisible, setIsSellModalVisible] = useState(false)
  const [isBorrowModalVisible, setIsBorrowModalVisible] = useState(false)

  useEffect(() => {
      fetchVaultAllocations()
  }, [])

  const fetchVaultAllocations = async () => {
    try {
      return vaultAllocations
    } catch (error) {
      enqueueSnackbar('Failed to fetch vault allocations', { variant: 'error' })
    } finally {
      setLoading(false)
    }
  }

  const handleSell = async () => {
    if (!selectedProperty) return
    try {
     
      enqueueSnackbar('Property part sold successfully', { variant: 'success' })
      fetchVaultAllocations()
    } catch (error) {
      enqueueSnackbar('Failed to sell property part', { variant: 'error' })
    } finally {
      setIsSellModalVisible(false)
    }
  }

  const handleBorrow = async () => {
    if (!selectedProperty) return
    try {
     
      enqueueSnackbar('Borrowed against property part successfully', {
        variant: 'success',
      })
      fetchVaultAllocations()
    } catch (error) {
      enqueueSnackbar('Failed to borrow against property part', {
        variant: 'error',
      })
    } finally {
      setIsBorrowModalVisible(false)
    }
  }

  const handlePropertyClick = (propertyId: number) => {
    router.push(`/properties/${propertyId}`)
  }

  const columns = [
    {
      title: 'Property',
      dataIndex: 'property',
      key: 'property',
      render: (property: any) => (
        <a onClick={() => handlePropertyClick(property.id)}>{property.name}</a>
      ),
    },
    {
      title: 'Allocation',
      dataIndex: 'allocation',
      key: 'allocation',
      render: (allocation: number) => `${allocation}%`,
    },
    {
      title: 'Value',
      dataIndex: 'value',
      key: 'value',
      render: (value: number) => `$${value.toLocaleString()}`,
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (text: any, record: any) => (
        <Space size="middle">
          <Button
            type="primary"
            icon={<DollarCircleOutlined />}
            onClick={() => {
              setSelectedProperty(record)
              setIsSellModalVisible(true)
            }}
          >
            Sell
          </Button>
          <Button
            type="default"
            icon={<TransactionOutlined />}
            onClick={() => {
              setSelectedProperty(record)
              setIsBorrowModalVisible(true)
            }}
          >
            Borrow
          </Button>
        </Space>
      ),
    },
  ]

  return (
    <PageLayout layout="full-width">
      <Title level={2}>Vault Allocations</Title>
      <Text>View and manage your investments in real estate properties.</Text>
      <Table
        columns={columns}
        dataSource={vaultAllocations}
        loading={loading}
        rowKey="id"
        style={{ marginTop: 20 }}
      />
      <Modal
        title="Sell Property Part"
        visible={isSellModalVisible}
        onOk={handleSell}
        onCancel={() => setIsSellModalVisible(false)}
      >
        <p>Are you sure you want to sell this property part?</p>
      </Modal>
      <Modal
        title="Borrow Against Property Part"
        visible={isBorrowModalVisible}
        onOk={handleBorrow}
        onCancel={() => setIsBorrowModalVisible(false)}
      >
        <p>Are you sure you want to borrow against this property part?</p>
      </Modal>
    </PageLayout>
  )
}
